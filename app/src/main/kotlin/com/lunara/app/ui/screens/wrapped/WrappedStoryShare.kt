/**
 * Ankit Khatri KC (C) 2026
 * Licensed under GPL-3.0
 */

package com.lunara.app.ui.screens.wrapped

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.net.Uri
import androidx.core.content.FileProvider
import com.lunara.app.R
import com.lunara.app.ui.screens.wrapped.WrappedConstants
import com.lunara.app.ui.screens.wrapped.WrappedState
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

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Background - deep dark
        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#121212")
        }
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), bgPaint)

        // Period label
        val periodPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#1ED760")
            textSize = 48f
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(WrappedConstants.periodLabel(state.period).uppercase(), width / 2f, 240f, periodPaint)

        // Header
        val headerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = 120f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText("Lunara Wrapped", width / 2f, 380f, headerPaint)

        // Stats section - weekly only
        val topSong = state.topSongs.firstOrNull()
        val topArtist = state.topArtists.firstOrNull()

        val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#B3B3B3")
            textSize = 44f
            typeface = Typeface.DEFAULT
        }

        val valuePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = 64f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }

        val stats = listOf(
            Pair("Top Song", topSong?.title ?: "—"),
            Pair("Top Artist", topArtist?.artist?.name ?: "—"),
            Pair("Unique Songs", state.uniqueSongCount.toString()),
            Pair("Unique Artists", state.uniqueArtistCount.toString()),
        )

        var y = 520f
        for ((label, value) in stats) {
            canvas.drawText(label, width / 2f - 260f, y, labelPaint)
            canvas.drawText(value, width / 2f + 260f, y, valuePaint)
            y += 110f
        }

        // Footer
        val footerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#B3B3B3")
            textSize = 40f
            typeface = Typeface.DEFAULT
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText("Share your Lunara Wrapped", width / 2f, height - 120f, footerPaint)

        return bitmap
    }
}
