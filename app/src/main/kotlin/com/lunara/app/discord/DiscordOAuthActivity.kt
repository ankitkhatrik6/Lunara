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
import kotlinx.coroutines.CancellationException
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

        @Volatile
        private var deferred: CompletableDeferred<AuthCodeResult>? = null

        fun newDeferred(): CompletableDeferred<AuthCodeResult> {
            val d = CompletableDeferred<AuthCodeResult>()
            deferred = d
            return d
        }

        suspend fun awaitCode(timeoutMs: Long = 120_000L): AuthCodeResult {
            val d = deferred ?: throw CancellationException("No pending authorization")
            return withTimeout(timeoutMs) { d.await() }
        }

        fun cancelPending() {
            deferred?.let { d ->
                if (!d.isCompleted) {
                    d.completeExceptionally(CancellationException("Authorization cancelled by user"))
                }
            }
        }
    }

    // True once the authorize URL has been handed to a browser. Used to detect a
    // "user came back without completing" and to avoid re-opening the browser.
    private var browserLaunched = false

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
        // onNewIntent(). We intentionally do NOT finish here so the process stays
        // alive while the user is in the browser.
        browserLaunched = true
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
        }
    }

    private fun launchCustomTabs(authUrl: String) {
        try {
            val customTabsIntent = CustomTabsIntent.Builder().build()
            customTabsIntent.launchUrl(this, Uri.parse(authUrl))
        } catch (e: ActivityNotFoundException) {
            Timber.tag(TAG).e(e, "OAuthActivity: no browser available to open authorize URL")
            deferred?.completeExceptionally(DiscordAuthException.NoBrowser())
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
        // Reaching here means the browser was shown and we returned to the
        // foreground without a redirect having completed us (a successful redirect
        // finishes us inside onNewIntent before onRestart runs). So the user backed
        // out of the browser: cancel the pending login so the caller is not stuck.
        if (browserLaunched) {
            Timber.tag(TAG).i("OAuthActivity: returned from browser without redirect; cancelling")
            cancelPending()
            finish()
        }
    }

    override fun onDestroy() {
        // Release any still-pending login so the caller isn't left waiting for the
        // full timeout.
        cancelPending()
        super.onDestroy()
    }

    private fun handleIntent(intent: Intent?) {
        val uri = intent?.data
        if (uri == null || uri.scheme != SCHEME) {
            Timber.tag(TAG).w("OAuthActivity: intent had no usable redirect URI")
            finish()
            return
        }
        completeFromUri(uri)
    }

    private fun completeFromUri(uri: Uri) {
        val code = uri.getQueryParameter("code")
        val state = uri.getQueryParameter("state")
        val error = uri.getQueryParameter("error")

        if (error != null) {
            Timber.tag(TAG).w("OAuthActivity: error=%s", error)
            deferred?.completeExceptionally(
                DiscordAuthException.UserCancelled("Authorization denied: $error"),
            )
            finish()
            return
        }

        if (code == null) {
            Timber.tag(TAG).w("OAuthActivity: missing code in redirect")
            deferred?.completeExceptionally(
                DiscordAuthException.InvalidGrant("Missing authorization code"),
            )
            finish()
            return
        }

        Timber.tag(TAG).i("OAuthActivity: received code (length=%d)", code.length)
        deferred?.complete(AuthCodeResult(code = code, state = state ?: ""))
        finish()
    }
}
