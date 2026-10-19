/**
 * Ankit Khatri KC (C) 2026
 * Metrolist Project (C) 2026
 * Licensed under GPL-3.0
 */

package com.lunara.app.ui.screens.wrapped

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.view.View
import android.view.ViewGroup
import androidx.compose.ui.platform.ComposeView
import androidx.core.content.FileProvider
import com.lunara.app.R
import com.lunara.app.ui.screens.wrapped.pages.WrappedStoryScreen
import java.io.File
import java.io.FileOutputStream

/**
 * Renders the Wrapped story UI to a PNG image and shares it through the system chooser.
 *
 * The image is written to the app cache directory, which is already exposed by
 * `provider_paths.xml` (`<cache-path name="cache" path="." />`) under the
 * `${applicationId}.FileProvider` authority, so no manifest change is needed.
 */
object WrappedStoryShare {

    private const val FILE_NAME = "lunara_wrapped_story.png"

    /**
     * Share the current Wrapped state as a story image.
     *
     * @param host the hosting [Activity], used to launch the chooser.
     * @param state the prepared [WrappedState] to render.
     */
    fun share(host: Activity, state: WrappedState) {
        val file = File(host.cacheDir, FILE_NAME)
        val bitmap = renderStoryToBitmap(host, state)
        FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 92, out)
        }
        bitmap.recycle()

        val uri = FileProvider.getUriForFile(host, "${host.packageName}.FileProvider", file)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        }
        host.startActivity(Intent.createChooser(intent, host.getString(R.string.wrapped_story_share)))
    }

    private fun renderStoryToBitmap(context: Context, state: WrappedState): Bitmap {
        // Phone-story dimensions so the shared image looks like a real story card
        val width = 1080
        val height = 1920

        val composeView = ComposeView(context).apply {
            layoutParams = ViewGroup.LayoutParams(width, height)
            setContent {
                WrappedStoryScreen(
                    state = state,
                    onShare = {},
                    onClose = {}
                )
            }
        }

        val spec = View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY)
        composeView.measure(spec, spec)
        composeView.layout(0, 0, width, height)

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        composeView.draw(Canvas(bitmap))
        return bitmap
    }
}
