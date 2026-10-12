package com.lunara.app.discord

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.util.Base64
import com.lunara.app.BuildConfig
import com.lunara.app.discord.DiscordDefaults.DISCORD_OAUTH_AUTHORIZE
import com.lunara.app.discord.DiscordDefaults.DISCORD_OAUTH_TOKEN
import com.lunara.app.discord.DiscordDefaults.DISCORD_SCOPES
import io.ktor.client.HttpClient
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.forms.submitForm
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import io.ktor.http.parameters
import kotlinx.coroutines.TimeoutCancellationException
import org.json.JSONObject
import timber.log.Timber
import java.io.IOException
import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.security.SecureRandom

data class DiscordAuthResult(
    val accessToken: String,
    val refreshToken: String,
    val expiresInSec: Long,
    val scope: String,
)

data class PkcePair(val verifier: String, val challenge: String)

sealed class DiscordAuthException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class UserCancelled(message: String = "User cancelled authorization") : DiscordAuthException(message)
    class Timeout(message: String = "Authorization timed out") : DiscordAuthException(message)
    class NetworkFailure(cause: Throwable) : DiscordAuthException("Network failure: ${cause.message}", cause)
    class RateLimited(message: String = "Discord is rate limiting requests; try again shortly") : DiscordAuthException(message)
    class InvalidGrant(message: String = "Invalid or expired grant") : DiscordAuthException(message)
    class StateMismatch : DiscordAuthException("OAuth state mismatch")
    class NoBrowser(message: String = "No browser available") : DiscordAuthException(message)
}

class DiscordAuth(
    private val httpClient: HttpClient = defaultClient(),
) {

    suspend fun authorize(activity: Activity): DiscordAuthResult {
        val pkce = generatePkcePair()
        val state = generateState()
        DiscordOAuthActivity.newDeferred()

        try {
            val authUrl = buildAuthorizeUrl(
                clientId = BuildConfig.DISCORD_APP_ID,
                redirectUri = REDIRECT_URI,
                state = state,
                challenge = pkce.challenge,
            )

            Timber.tag(TAG).i(
                "authorize: launching consent screen (clientId prefix=%s, redirect=%s, scopes=%s)",
                BuildConfig.DISCORD_APP_ID.toString().take(8),
                REDIRECT_URI,
                DISCORD_SCOPES,
            )
            // NOTE: the full authorize URL is intentionally NOT logged — it carries the
            // OAuth `state` and the PKCE `code_challenge`, both of which are secrets.

            // DiscordOAuthActivity opens the authorize page in a Chrome Custom Tab and
            // catches the lunaradiscord:// redirect through its manifest intent-filter.
            // This is reliable across devices; an in-app WebView previously failed to
            // intercept the custom-scheme redirect, surfacing as "didn't return".
            val intent = Intent(activity, DiscordOAuthActivity::class.java).apply {
                putExtra(DiscordOAuthActivity.EXTRA_AUTH_URL, authUrl)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            try {
                activity.startActivity(intent)
            } catch (e: ActivityNotFoundException) {
                Timber.tag(TAG).w(e, "authorize: could not launch OAuth activity")
                cancel()
                throw DiscordAuthException.NoBrowser()
            }

            val callback = try {
                DiscordOAuthActivity.awaitCode(timeoutMs = 120_000L)
            } catch (e: TimeoutCancellationException) {
                // Distinct from an explicit user cancellation: the consent screen never
                // returned within the budget. Report it as its own actionable error.
                cancel()
                throw DiscordAuthException.Timeout()
            } catch (e: DiscordAuthException.UserCancelled) {
                // Already a meaningful user-cancellation (denied, backed out, superseded).
                throw e
            }
            // Any other CancellationException means the *calling* coroutine was cancelled
            // (e.g. scope teardown). Preserve it rather than masking it as a user cancel.

            if (callback.state != state) {
                Timber.tag(TAG).w(
                    "authorize: state mismatch (expectedLen=%d, gotLen=%d)",
                    state.length,
                    callback.state.length,
                )
                throw DiscordAuthException.StateMismatch()
            }

            return exchangeAuthorizationCode(
                code = callback.code,
                verifier = pkce.verifier,
                redirectUri = REDIRECT_URI,
            )
        } finally {
            // no cleanup needed — no local server
        }
    }

    fun cancel() {
        DiscordOAuthActivity.cancelPending()
    }

    fun close() {
        runCatching { httpClient.close() }
    }

    suspend fun refresh(refreshToken: String): DiscordAuthResult = refreshAccessToken(refreshToken)

    private suspend fun exchangeAuthorizationCode(
        code: String,
        verifier: String,
        redirectUri: String,
    ): DiscordAuthResult = performTokenExchange(
        grantType = "authorization_code",
        extraParams = parameters {
            append("code", code)
            append("redirect_uri", redirectUri)
            append("code_verifier", verifier)
        },
    )

    private suspend fun refreshAccessToken(refreshToken: String): DiscordAuthResult =
        performTokenExchange(
            grantType = "refresh_token",
            extraParams = parameters {
                append("refresh_token", refreshToken)
            },
        )

    private suspend fun performTokenExchange(
        grantType: String,
        extraParams: io.ktor.http.Parameters,
    ): DiscordAuthResult {
        val response: HttpResponse = httpClient.submitForm(
            url = DISCORD_OAUTH_TOKEN,
            formParameters = parameters {
                append("client_id", BuildConfig.DISCORD_APP_ID.toString())
                append("grant_type", grantType)
                extraParams.forEach { name, values ->
                    values.forEach { value -> append(name, value) }
                }
            },
        )

        val status = response.status
        val body = response.bodyAsText()

        if (status.value in 200..299) {
            val json = JSONObject(body)
            val accessToken = json.optString("access_token", "")
            if (accessToken.isEmpty()) {
                Timber.tag(TAG).w("token exchange: 2xx response missing access_token (grantType=%s)", grantType)
                throw DiscordAuthException.InvalidGrant("Token response missing access_token")
            }
            val refreshToken = json.optString("refresh_token", "")
            val expiresIn = json.optLong("expires_in", 0L)
            val scope = json.optString("scope", DISCORD_SCOPES)
            Timber.tag(TAG).i(
                "token exchange: success (accessToken length=%d, refreshToken present=%s, expiresIn=%d)",
                accessToken.length,
                refreshToken.isNotEmpty(),
                expiresIn,
            )
            return DiscordAuthResult(
                accessToken = accessToken,
                refreshToken = refreshToken,
                expiresInSec = expiresIn,
                scope = scope,
            )
        }

        val errorCode = runCatching { JSONObject(body).optString("error", "") }
            .getOrDefault("")
        // Log only the machine-readable error code — never the raw body, which can echo
        // request parameters. Build user-facing messages from the code, not the body.
        Timber.tag(TAG).w(
            "token exchange: HTTP %d (grantType=%s, error=%s)",
            status.value,
            grantType,
            errorCode.ifEmpty { "unknown" },
        )

        when {
            status == HttpStatusCode.TooManyRequests ->
                throw DiscordAuthException.RateLimited()

            status == HttpStatusCode.BadRequest -> when (errorCode) {
                "invalid_grant" -> throw DiscordAuthException.InvalidGrant()
                "invalid_client", "unauthorized_client" ->
                    throw DiscordAuthException.InvalidGrant("Client not authorized for this grant")
                "invalid_request", "unsupported_grant_type" ->
                    throw DiscordAuthException.InvalidGrant("Malformed token request: $errorCode")
                else ->
                    throw DiscordAuthException.InvalidGrant("Token request rejected: ${errorCode.ifEmpty { "invalid_request" }}")
            }

            status == HttpStatusCode.Unauthorized || status == HttpStatusCode.Forbidden ->
                throw DiscordAuthException.InvalidGrant("Token endpoint rejected credentials (HTTP ${status.value})")

            status.value in 500..599 ->
                throw DiscordAuthException.NetworkFailure(IOException("Discord server error HTTP ${status.value}"))

            else ->
                throw DiscordAuthException.NetworkFailure(IOException("Unexpected HTTP ${status.value}"))
        }
    }

    private fun buildAuthorizeUrl(
        clientId: Long,
        redirectUri: String,
        state: String,
        challenge: String,
    ): String {
        val encodedRedirect = URLEncoder.encode(redirectUri, StandardCharsets.UTF_8.name())
        val encodedScope = URLEncoder.encode(DISCORD_SCOPES, StandardCharsets.UTF_8.name())
        return buildString {
            append(DISCORD_OAUTH_AUTHORIZE)
            append("?client_id=").append(clientId)
            append("&response_type=code")
            append("&redirect_uri=").append(encodedRedirect)
            append("&scope=").append(encodedScope)
            append("&state=").append(state)
            append("&code_challenge_method=S256")
            append("&code_challenge=").append(challenge)
        }
    }

    companion object {
        private const val TAG = "DiscordSvc"
        const val REDIRECT_URI = "lunaradiscord://oauth2/callback"

        private fun defaultClient(): HttpClient = HttpClient(CIO) {
            install(HttpTimeout) {
                requestTimeoutMillis = 15_000L
                connectTimeoutMillis = 10_000L
                socketTimeoutMillis = 15_000L
            }
            expectSuccess = false
        }

        fun generatePkcePair(): PkcePair {
            val bytes = ByteArray(64)
            SecureRandom().nextBytes(bytes)
            val verifier = Base64.encodeToString(
                bytes,
                Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP,
            )
            val challenge = Base64.encodeToString(
                MessageDigest.getInstance("SHA-256").digest(verifier.toByteArray(StandardCharsets.UTF_8)),
                Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP,
            )
            return PkcePair(verifier = verifier, challenge = challenge)
        }

        private fun generateState(): String {
            val bytes = ByteArray(16)
            SecureRandom().nextBytes(bytes)
            return Base64.encodeToString(
                bytes,
                Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP,
            )
        }
    }
}
