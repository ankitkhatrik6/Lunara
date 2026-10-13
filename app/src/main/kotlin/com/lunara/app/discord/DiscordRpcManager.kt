package com.lunara.app.discord

import android.app.Activity
import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.isActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONObject
import timber.log.Timber
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.atomic.AtomicLong

data class DiscordUser(
    val id: String,
    val username: String,
    val name: String,
    val avatar: String?,
)

object DiscordRpcManager {
    private const val TAG = "DiscordSvc"

    @Volatile
    private var initialized: Boolean = false

    @Volatile
    private var _ready: Boolean = false

    @Volatile
    private var _authorized: Boolean = false

    @Volatile
    private var accessToken: String? = null

    @Volatile
    private var authorizeInProgress: Boolean = false

    @Volatile
    private var lastActivitySentAtMs: Long = 0L

    @Volatile
    private var lastActivity: ActivityPayload? = null

    @Volatile private var currentSongId: String? = null
    @Volatile private var currentIsPlaying: Boolean = false
    private val currentActivityId = AtomicLong(0L)
    @Volatile private var imageResolutionJob: Job? = null
    @Volatile private var currentActivityHadImages: Boolean = false
    private val reconnectMutex = Mutex()

    private val _accessTokenFlow = MutableStateFlow<String?>(null)
    val accessTokenFlow: StateFlow<String?> = _accessTokenFlow

    private val _connectionStatus = MutableStateFlow(Status.Disconnected)
    val connectionStatus: StateFlow<Status> = _connectionStatus

    private val _lastError = MutableStateFlow<String?>(null)
    val lastError: StateFlow<String?> = _lastError

    private val _currentUser = MutableStateFlow<DiscordUser?>(null)
    val currentUser: StateFlow<DiscordUser?> = _currentUser

    private val _settingsChanged = MutableStateFlow(0)
    val settingsChanged: StateFlow<Int> = _settingsChanged

    fun notifySettingsChanged() {
        Timber.tag(TAG).d("notifySettingsChanged: incrementing (count=%d), invalidating dedup", _settingsChanged.value + 1)
        _settingsChanged.value++
        currentSongId = null
        currentIsPlaying = false
    }

    enum class Status { Disconnected, Authorizing, Connected }

    fun getAccessToken(): String? = accessToken

    fun isInitialized(): Boolean = initialized

    fun isAuthorized(): Boolean = _authorized

    fun isReady(): Boolean = _ready

    fun isShowingSong(songId: String, isPlaying: Boolean): Boolean {
        if (currentSongId != songId || currentIsPlaying != isPlaying) {
            return false
        }
        if (lastActivity == null) {
            return false
        }
        // If the last activity had images to resolve but none were sent,
        // and no resolution is in progress, allow the caller to retry.
        if (currentActivityHadImages &&
            lastActivity?.largeImage == null && lastActivity?.smallImage == null &&
            (imageResolutionJob == null || imageResolutionJob?.isCompleted == true)
        ) {
            return false
        }
        return true
    }

    fun clearLastError() {
        _lastError.value = null
    }

    private var scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val appId: String = BuildConfigProvider.appId

    private val auth: DiscordAuth = DiscordAuth()

    // Discord Rich Presence on Android is published through the Discord Social SDK,
    // a native library this build does not ship. Discord's normal Gateway must NOT be
    // driven with a user OAuth token, so this manager performs OAuth sign-in (identify)
    // and shows the linked account, but opens no presence transport. setActivity/clear
    // are intentional no-ops that only record state for de-duplication.

    fun init(context: Context) {
        DiscordTokenStore.init(context.applicationContext)
        if (initialized && scope.isActive) {
            Timber.tag(TAG).i("init: already initialized and active, skipping")
            return
        }
        if (!scope.isActive) {
            Timber.tag(TAG).i("init: recreating scope after previous destroy")
            scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
        }
        initialized = true
        _connectionStatus.value = Status.Disconnected
        Timber.tag(TAG).i("init: token store initialized, scheduling auto-rehydrate")

        scope.launch {
            val saved = DiscordTokenStore.retrieveSuspend()
            if (!saved.isNullOrEmpty()) {
                Timber.tag(TAG).i("init: found persisted token, reconnecting")
                reconnectWithToken(saved)
            } else {
                Timber.tag(TAG).i("init: no persisted token, waiting for explicit authorize")
            }
        }
    }

    fun authorize(activity: Activity, onComplete: (Boolean) -> Unit) {
        if (authorizeInProgress) {
            Timber.tag(TAG).w("authorize: already in progress, ignoring double-tap")
            scope.launch(Dispatchers.Main) { onComplete(false) }
            return
        }
        authorizeInProgress = true

        fun completeWith(success: Boolean) {
            scope.launch(Dispatchers.Main) { onComplete(success) }
        }

        if (_ready && _authorized) {
            Timber.tag(TAG).d("authorize: short-circuit — already ready and authorized")
            authorizeInProgress = false
            scope.launch(Dispatchers.Main) { onComplete(true) }
            return
        }
        if (_authorized) {
            Timber.tag(TAG).d("authorize: short-circuit — authorized but not ready, reconnecting")
            authorizeInProgress = false
            reconnectWithToken(accessToken ?: "")
            scope.launch(Dispatchers.Main) { onComplete(true) }
            return
        }

        _connectionStatus.value = Status.Authorizing
        _lastError.value = null

        scope.launch {
            try {
                val result = auth.authorize(activity)
                DiscordTokenStore.storeFull(
                    result.accessToken,
                    result.refreshToken,
                    result.expiresInSec,
                )
                accessToken = result.accessToken
                _accessTokenFlow.value = result.accessToken
                _authorized = true
                _connectionStatus.value = Status.Connected

                // Fetch the linked account so the settings screen can show who signed
                // in. This uses the officially supported GET /users/@me with the
                // identify scope. Rich Presence itself is published via the Discord
                // Social SDK, which this build does not include, so no presence
                // transport is opened here.
                val user = fetchCurrentUser(result.accessToken)
                if (user != null) {
                    _currentUser.value = user
                    Timber.tag(TAG).i("authorize: signed in as %s", user.username)
                } else {
                    Timber.tag(TAG).w("authorize: signed in but could not fetch profile")
                }
                completeWith(true)
            } catch (e: DiscordAuthException.AccessDenied) {
                Timber.tag(TAG).i("authorize: user denied authorization")
                _lastError.value = "discord_error_access_denied"
                _connectionStatus.value = Status.Disconnected
                completeWith(false)
            } catch (e: DiscordAuthException.InvalidScope) {
                // A requested scope (e.g. the approval-gated rpc scope) is not available
                // to this application. Surface it as its own actionable error.
                Timber.tag(TAG).w(e, "authorize: invalid/unauthorized scope")
                _lastError.value = "discord_error_invalid_scope"
                _connectionStatus.value = Status.Disconnected
                completeWith(false)
            } catch (e: DiscordAuthException.UserCancelled) {
                Timber.tag(TAG).i("authorize: user cancelled")
                _lastError.value = "discord_error_callback_timeout"
                _connectionStatus.value = Status.Disconnected
                completeWith(false)
            } catch (e: DiscordAuthException.Timeout) {
                Timber.tag(TAG).w(e, "authorize: timed out waiting for the redirect callback")
                _lastError.value = "discord_error_callback_timeout"
                _connectionStatus.value = Status.Disconnected
                completeWith(false)
            } catch (e: DiscordAuthException.RateLimited) {
                Timber.tag(TAG).w(e, "authorize: rate limited by Discord")
                _lastError.value = "discord_error_gateway_failed"
                _connectionStatus.value = Status.Disconnected
                completeWith(false)
            } catch (e: DiscordAuthException.StateMismatch) {
                Timber.tag(TAG).w(e, "authorize: state mismatch")
                _lastError.value = "discord_error_invalid_scope"
                _connectionStatus.value = Status.Disconnected
                completeWith(false)
            } catch (e: DiscordAuthException.NetworkFailure) {
                Timber.tag(TAG).e(e, "authorize: network failure")
                _lastError.value = "discord_error_gateway_failed"
                _connectionStatus.value = Status.Disconnected
                completeWith(false)
            } catch (e: DiscordAuthException.NoBrowser) {
                Timber.tag(TAG).w(e, "authorize: no browser available")
                _lastError.value = "discord_error_no_browser"
                _connectionStatus.value = Status.Disconnected
                completeWith(false)
            } catch (e: DiscordAuthException.InvalidGrant) {
                Timber.tag(TAG).w(e, "authorize: invalid grant")
                _lastError.value = "discord_error_token_refresh_failed"
                _connectionStatus.value = Status.Disconnected
                completeWith(false)
            } catch (e: Throwable) {
                Timber.tag(TAG).e(e, "authorize: unexpected failure")
                _lastError.value = "discord_error_loopback_timeout"
                _connectionStatus.value = Status.Disconnected
                completeWith(false)
            } finally {
                authorizeInProgress = false
            }
        }
    }

    fun cancelAuthorize() {
        Timber.tag(TAG).i("cancelAuthorize: cancelling active authorization")
        auth.cancel()
    }

    fun fetchCurrentUser(token: String): DiscordUser? {
        return try {
            val url = URL("https://discord.com/api/v10/users/@me")
            val conn = url.openConnection() as HttpURLConnection
            conn.connectTimeout = 10_000
            conn.readTimeout = 10_000
            conn.requestMethod = "GET"
            conn.setRequestProperty("Authorization", "Bearer $token")
            conn.setRequestProperty("Accept", "application/json")

            val responseCode = conn.responseCode
            val responseBody = if (responseCode in 200..299) {
                conn.inputStream.bufferedReader().readText()
            } else {
                conn.errorStream?.bufferedReader()?.readText() ?: ""
            }
            conn.disconnect()

            if (responseCode !in 200..299) {
                Timber.tag(TAG).w("fetchCurrentUser: HTTP $responseCode body=$responseBody")
                return null
            }

            val json = JSONObject(responseBody)
            val id = json.getString("id")
            val username = json.getString("username")
            val name = json.optString("global_name", username)
            val avatarHash = json.optString("avatar")
            val avatar = if (avatarHash.isNotEmpty() && avatarHash != "null") {
                "https://cdn.discordapp.com/avatars/$id/$avatarHash.png"
            } else null

            DiscordUser(id, username, name, avatar)
        } catch (e: Exception) {
            Timber.tag(TAG).e(e, "fetchCurrentUser: exception")
            null
        }
    }

    // Rich Presence is published on Android through the Discord Social SDK, a native
    // library this build does not include. Discord's normal Gateway must not be driven
    // with a user OAuth token, and there is no other officially supported way to set a
    // user's activity from a third-party Android app. So publishing is a no-op here: we
    // record the current song/playback state for de-duplication (so callers don't spin)
    // and log that a supported transport is required. We never fake success.
    fun setActivity(
        activity: DiscordActivity,
        songId: String? = null,
        isPlaying: Boolean = true,
        status: PresenceStatus = PresenceStatus.Online,
    ) {
        currentSongId = songId
        currentIsPlaying = isPlaying
        lastActivitySentAtMs = System.currentTimeMillis()
        Timber.tag(TAG).d(
            "setActivity: no supported presence transport in this build (name=%s, songId=%s, isPlaying=%s); not publishing",
            activity.name, songId, isPlaying,
        )
    }

    fun clear() {
        currentSongId = null
        currentIsPlaying = false
        lastActivity = null
        currentActivityHadImages = false
        currentActivityId.incrementAndGet()
        Timber.tag(TAG).d("clear: no supported presence transport in this build; nothing to clear")
    }

    fun reconnectWithToken(token: String) {
        if (!initialized) {
            Timber.tag(TAG).w("reconnectWithToken: not initialized, ignoring")
            return
        }

        scope.launch {
            reconnectMutex.withLock {
                accessToken = token
                _accessTokenFlow.value = token
                DiscordTokenStore.storeAccessToken(token)
                _connectionStatus.value = Status.Authorizing
                try {
                    val refreshToken = DiscordTokenStore.getRefreshToken()
                    val expiresAt = DiscordTokenStore.getExpiresAt()
                    val nowSec = System.currentTimeMillis() / 1000L
                    val needsRefresh = !refreshToken.isNullOrEmpty() &&
                        expiresAt > 0L &&
                        (expiresAt - nowSec) < 3600L

                    Timber.tag(TAG).i(
                        "reconnectWithToken: hasRefreshToken=%s, expiresAt=%d, now=%d, needsRefresh=%s",
                        !refreshToken.isNullOrEmpty(),
                        expiresAt,
                        nowSec,
                        needsRefresh,
                    )

                    if (needsRefresh) {
                        Timber.tag(TAG).i("reconnectWithToken: proactive token refresh")
                        val refreshed = try {
                            auth.refresh(refreshToken)
                        } catch (e: DiscordAuthException.InvalidGrant) {
                            Timber.tag(TAG).w(e, "reconnectWithToken: refresh invalid_grant, logging out")
                            _lastError.value = "discord_error_token_refresh_failed"
                            logout()
                            return@withLock
                        } catch (e: Throwable) {
                            Timber.tag(TAG).w(e, "reconnectWithToken: refresh failed, continuing with old token")
                            null
                        }
                        if (refreshed != null) {
                            Timber.tag(TAG).i(
                                "reconnectWithToken: refresh succeeded (new token length=%d, expiresIn=%d)",
                                refreshed.accessToken.length,
                                refreshed.expiresInSec,
                            )
                            accessToken = refreshed.accessToken
                            _accessTokenFlow.value = refreshed.accessToken
                            DiscordTokenStore.storeFull(
                                refreshed.accessToken,
                                refreshed.refreshToken,
                                refreshed.expiresInSec,
                            )
                        }
                    }

                    // No presence transport (see setActivity). Rehydration only
                    // validates/refreshes the token so the linked account still shows.
                    _authorized = true
                    _connectionStatus.value = Status.Connected
                    val user = fetchCurrentUser(accessToken ?: token)
                    if (user != null) {
                        _currentUser.value = user
                    }
                    Timber.tag(TAG).i("reconnectWithToken: token revalidated (user=%s)", user?.username)
                } catch (e: Throwable) {
                    Timber.tag(TAG).e(e, "reconnectWithToken: revalidation failed")
                    _lastError.value = "discord_error_loopback_timeout"
                    _connectionStatus.value = Status.Disconnected
                }
            }
        }
    }

    fun disconnect() {
        Timber.tag(TAG).i("disconnect: clearing authorized state")
        currentActivityId.incrementAndGet()
        _connectionStatus.value = Status.Disconnected
        _ready = false
        _authorized = false
        currentSongId = null
        currentIsPlaying = false
        currentActivityHadImages = false
    }

    fun destroy() {
        Timber.tag(TAG).i("destroy: cancelling scope and tearing down (initialized=%s)", initialized)
        currentActivityId.incrementAndGet()
        scope.cancel()
        _ready = false
        _authorized = false
        initialized = false
        _connectionStatus.value = Status.Disconnected
        lastActivity = null
        currentSongId = null
        currentIsPlaying = false
        currentActivityHadImages = false
    }

    fun logout() {
        Timber.tag(TAG).i("logout: clearing tokens and disconnecting")
        disconnect()
        accessToken = null
        _accessTokenFlow.value = null
        _currentUser.value = null
        DiscordTokenStore.clear()
        DiscordSuperProperties.reset()
        _lastError.value = null
        lastActivity = null
        currentActivityHadImages = false
    }

}

private object BuildConfigProvider {
    val appId: String = com.lunara.app.BuildConfig.DISCORD_APP_ID.toString()
}
