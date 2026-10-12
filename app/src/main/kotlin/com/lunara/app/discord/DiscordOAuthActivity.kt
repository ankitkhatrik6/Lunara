package com.lunara.app.discord

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.withTimeout
import timber.log.Timber

data class AuthCodeResult(val code: String, val state: String)

/**
 * Hosts the Discord OAuth2 flow in an in-app WebView.
 *
 * The authorize page is loaded here and the redirect to [REDIRECT_PREFIX] is
 * intercepted directly, so the flow never leaves the app. Relying on an external
 * browser to hand the custom-scheme redirect back was unreliable: some browsers
 * swallow it, and with the browser in the foreground the app process could be
 * killed, losing the pending login — both surfaced as "sign-in didn't return".
 *
 * The manifest intent-filter for [REDIRECT_PREFIX] is kept as a fallback for a
 * redirect that still arrives from outside (e.g. a previously opened browser tab).
 */
class DiscordOAuthActivity : Activity() {

    companion object {
        private const val TAG = "DiscordSvc"
        const val EXTRA_AUTH_URL = "extra_auth_url"
        const val REDIRECT_PREFIX = "lunaradiscord://oauth2/callback"

        // WebViewClient.ERROR_UNKNOWN_URL_SCHEME — the code a WebView reports when it
        // is asked to load a scheme it cannot handle (our custom redirect). Kept as a
        // literal so it does not depend on the API-level constant being inlined.
        private const val ERROR_UNKNOWN_URL_SCHEME = -10

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

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val authUrl = intent?.getStringExtra(EXTRA_AUTH_URL)
        if (authUrl.isNullOrBlank()) {
            // Launched from outside via the redirect intent-filter; finish it here.
            handleIntent(intent)
            return
        }

        Timber.tag(TAG).i("OAuthActivity: hosting authorize flow in WebView")

        val webView = WebView(this).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            @SuppressLint("SetJavaScriptEnabled")
            settings.javaScriptCanOpenWindowsAutomatically = true
            settings.setSupportMultipleWindows(true)
            webViewClient = object : WebViewClient() {
                // Deprecated overload: still called for some redirect paths (e.g. JS
                // navigations), where the WebResourceRequest version is skipped.
                @Deprecated("Matches legacy redirect callbacks")
                override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                    if (url != null && handleRedirect(url)) return true
                    return super.shouldOverrideUrlLoading(view, url)
                }

                override fun shouldOverrideUrlLoading(
                    view: WebView?,
                    request: WebResourceRequest?,
                ): Boolean {
                    val url = request?.url?.toString()
                    if (url != null && handleRedirect(url)) return true
                    return super.shouldOverrideUrlLoading(view, request)
                }

                // A custom scheme the WebView cannot load (lunaradiscord://) surfaces
                // here as ERROR_UNKNOWN_URL_SCHEME. This is the most reliable place to
                // catch the redirect on many devices, so the URL is recovered from it.
                override fun onReceivedError(
                    view: WebView?,
                    request: WebResourceRequest?,
                    error: WebResourceError?,
                ) {
                    val url = request?.url?.toString()
                    if (request?.isForMainFrame == true && url != null &&
                        error?.errorCode == ERROR_UNKNOWN_URL_SCHEME
                    ) {
                        Timber.tag(TAG).i("OAuthActivity: redirect caught via onReceivedError")
                        if (handleRedirect(url)) return
                    }
                    super.onReceivedError(view, request, error)
                }
            }
            loadUrl(authUrl)
        }
        setContentView(webView)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        // A redirect that arrived from outside (browser fallback) with singleTask.
        setIntent(intent)
        handleIntent(intent)
    }

    override fun onDestroy() {
        // If the user backed out before finishing, release the pending login so the
        // caller isn't left waiting for the full timeout.
        cancelPending()
        super.onDestroy()
    }

    private fun handleRedirect(url: String): Boolean {
        if (!url.startsWith(REDIRECT_PREFIX)) return false
        Timber.tag(TAG).i("OAuthActivity: redirect matched (%s)", url.take(48))
        completeFromUri(Uri.parse(url))
        return true
    }

    private fun handleIntent(intent: Intent?) {
        val uri = intent?.data ?: run {
            Timber.tag(TAG).w("OAuthActivity: no URI in intent")
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
                DiscordAuthException.UserCancelled("Authorization denied: $error")
            )
            finish()
            return
        }

        if (code == null) {
            Timber.tag(TAG).w("OAuthActivity: missing code")
            deferred?.completeExceptionally(
                DiscordAuthException.InvalidGrant("Missing authorization code")
            )
            finish()
            return
        }

        Timber.tag(TAG).i("OAuthActivity: received code (length=%d)", code.length)
        deferred?.complete(AuthCodeResult(code = code, state = state ?: ""))
        finish()
    }
}

