package com.lunara.app.discord

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.TextView
import androidx.browser.customtabs.CustomTabsIntent
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.withTimeout
import timber.log.Timber

data class AuthCodeResult(val code: String, val state: String)

/**
 * Hosts the Discord OAuth2 authorization-code + PKCE flow.
 *
 * The authorize page is opened in a Chrome Custom Tab (a real browser that shares
 * cookies and opens popups correctly). Discord then redirects to the custom
 * scheme [REDIRECT_PREFIX]; the browser cannot handle that scheme, so it fires an
 * Android VIEW intent that this activity catches through its manifest intent-filter
 * (the activity is [android.R.attr.launchMode singleTask], so a redirect while the
 * launcher is still alive arrives via [onNewIntent]).
 *
 * This is the standard, reliable pattern. An in-app WebView was previously used but
 * it did not reliably intercept custom-scheme redirects on all devices, which
 * surfaced as "sign-in didn't return to the app".
 *
 * The launching activity deliberately stays alive (it is not finished after opening
 * the browser) so the process is not killed while the user is in the browser, and
 * so the redirect intent is delivered back to the same instance.
 */
class DiscordOAuthActivity : Activity() {

    companion object {
        private const val TAG = "DiscordSvc"
        const val EXTRA_AUTH_URL = "extra_auth_url"
        const val REDIRECT_PREFIX = "lunaradiscord://oauth2/callback"
        private const val SCHEME = "lunaradiscord"
        private const val HOST = "oauth2"
        private const val PATH = "/callback"

        /**
         * Lifecycle of a single authorization attempt. Stored in the companion so it
         * survives Activity recreation (config change / process-death restore) while
         * the browser is in front — the pending [deferred] must not be disturbed by a
         * transient teardown of this Activity instance.
         */
        private enum class Phase {
            Idle,
            BrowserLaunched,
            AwaitingCallback,
            Completed,
            Cancelled,
            Failed,
        }

        @Volatile
        private var deferred: CompletableDeferred<AuthCodeResult>? = null

        @Volatile
        private var phase: Phase = Phase.Idle

        /**
         * Registers a new pending authorization. A second attempt must never orphan
         * the first caller: any still-pending deferred is cancelled first so its
         * awaiter unblocks with a clear cancellation instead of silently losing its
         * result or hanging until its own timeout.
         */
        @Synchronized
        fun newDeferred(): CompletableDeferred<AuthCodeResult> {
            deferred?.let { previous ->
                if (!previous.isCompleted) {
                    Timber.tag(TAG).w("newDeferred: superseding a still-pending authorization")
                    previous.completeExceptionally(
                        DiscordAuthException.UserCancelled("Authorization superseded by a new attempt"),
                    )
                }
            }
            val d = CompletableDeferred<AuthCodeResult>()
            deferred = d
            phase = Phase.BrowserLaunched
            return d
        }

        suspend fun awaitCode(timeoutMs: Long = 120_000L): AuthCodeResult {
            val d = deferred ?: throw DiscordAuthException.UserCancelled("No pending authorization")
            return withTimeout(timeoutMs) { d.await() }
        }

        /**
         * Cancels a pending authorization. Idempotent and safe: it never touches an
         * already-[Phase.Completed] result, so a successful callback cannot be
         * overwritten by a later cancellation.
         */
        @Synchronized
        fun cancelPending() {
            if (phase == Phase.Completed) return
            val d = deferred
            if (d != null && !d.isCompleted) {
                d.completeExceptionally(
                    DiscordAuthException.UserCancelled("Authorization cancelled"),
                )
            }
            phase = Phase.Cancelled
        }

        @Synchronized
        private fun completeWith(result: AuthCodeResult) {
            phase = Phase.Completed
            deferred?.let { d ->
                if (!d.isCompleted) d.complete(result)
            }
        }

        @Synchronized
        private fun failWith(error: DiscordAuthException) {
            if (phase != Phase.Completed) phase = Phase.Failed
            deferred?.let { d ->
                if (!d.isCompleted) d.completeExceptionally(error)
            }
        }

        @Synchronized
        fun markAwaitingCallback() {
            if (phase == Phase.BrowserLaunched) phase = Phase.AwaitingCallback
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val authUrl = intent?.getStringExtra(EXTRA_AUTH_URL)
        if (authUrl.isNullOrBlank()) {
            // Launched by the redirect intent-filter: the browser sent us back.
            handleIntent(intent)
            return
        }

        // Launch mode: show a small placeholder and open the authorize page in a
        // Custom Tab. The redirect is delivered back to this instance via
        // onNewIntent() (singleTask), or to a freshly created instance if this one
        // was killed while the browser was in front. We intentionally do NOT finish
        // here so the process stays alive while the user is in the browser.
        setContentView(
            FrameLayout(this).apply {
                addView(
                    TextView(this@DiscordOAuthActivity).apply {
                        text = "Opening Discord authorization\u2026"
                        textSize = 16f
                        gravity = Gravity.CENTER
                    },
                )
            },
        )

        if (savedInstanceState == null) {
            launchCustomTabs(authUrl)
        } else {
            // Recreated while the browser is still open: keep awaiting the callback
            // without launching a second browser tab.
            markAwaitingCallback()
        }
    }

    private fun launchCustomTabs(authUrl: String) {
        try {
            val customTabsIntent = CustomTabsIntent.Builder().build()
            customTabsIntent.launchUrl(this, Uri.parse(authUrl))
            markAwaitingCallback()
            Timber.tag(TAG).i("OAuthActivity: opened authorize page in a Custom Tab")
        } catch (e: ActivityNotFoundException) {
            Timber.tag(TAG).e(e, "OAuthActivity: no browser available to open authorize URL")
            failWith(DiscordAuthException.NoBrowser())
            finish()
        }
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun onRestart() {
        super.onRestart()
        // A successful redirect completes the deferred inside onNewIntent (which runs
        // before onRestart) and moves phase to Completed, so this branch is only
        // reached when the user returned from the browser without a redirect (pressed
        // back / closed the tab). Cancel the pending login so the caller is not stuck.
        // This is state-driven, not a bare "browserLaunched" flag, so it stays correct
        // across activity recreation.
        if (phase == Phase.AwaitingCallback || phase == Phase.BrowserLaunched) {
            Timber.tag(TAG).i("OAuthActivity: returned from browser without redirect; cancelling")
            cancelPending()
            finish()
        }
    }

    override fun onDestroy() {
        // Release a still-pending login only when this instance is going away for
        // good. A configuration-change recreation (isFinishing == false) must keep
        // the pending deferred alive so the browser redirect can still complete it.
        if (isFinishing && (phase == Phase.AwaitingCallback || phase == Phase.BrowserLaunched)) {
            cancelPending()
        }
        super.onDestroy()
    }

    private fun handleIntent(intent: Intent?) {
        val uri = intent?.data
        if (uri == null || !isValidRedirect(uri)) {
            Timber.tag(TAG).w("OAuthActivity: intent had no usable redirect URI")
            // Fail the pending authorization instead of just finishing, so the caller
            // is not left waiting for its full timeout.
            failWith(DiscordAuthException.InvalidGrant("Missing or invalid redirect URI"))
            finish()
            return
        }
        completeFromUri(uri)
    }

    /** Validate scheme, host, and path before trusting a callback. */
    private fun isValidRedirect(uri: Uri): Boolean {
        val path = uri.path
        return uri.scheme == SCHEME &&
            uri.host == HOST &&
            (path == PATH || (path != null && path.startsWith("$PATH/")))
    }

    private fun completeFromUri(uri: Uri) {
        val code = uri.getQueryParameter("code")
        val state = uri.getQueryParameter("state")
        val error = uri.getQueryParameter("error")

        if (error != null) {
            Timber.tag(TAG).w("OAuthActivity: authorization error=%s", error)
            // Map Discord's OAuth error codes to distinct, actionable failures.
            val failure = when (error) {
                "access_denied" -> DiscordAuthException.AccessDenied()
                "invalid_scope", "unauthorized_client" ->
                    DiscordAuthException.InvalidScope("Discord rejected a requested permission ($error)")
                else -> DiscordAuthException.UserCancelled("Authorization failed: $error")
            }
            failWith(failure)
            finish()
            return
        }

        if (code.isNullOrEmpty()) {
            Timber.tag(TAG).w("OAuthActivity: missing code in redirect")
            failWith(DiscordAuthException.InvalidGrant("Missing authorization code"))
            finish()
            return
        }

        if (state.isNullOrEmpty()) {
            // Never accept a missing/empty state. The caller compares it against the
            // original, so an empty value must fail rather than be substituted.
            Timber.tag(TAG).w("OAuthActivity: missing state in redirect")
            failWith(DiscordAuthException.StateMismatch())
            finish()
            return
        }

        Timber.tag(TAG).i("OAuthActivity: received code (length=%d)", code.length)
        completeWith(AuthCodeResult(code = code, state = state))
        finish()
    }
}
