/**
 * Ankit Khatri KC (C) 2026
 * Licensed under GPL-3.0
 */

package com.lunara.app.utils

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import androidx.core.content.ContextCompat
import androidx.core.graphics.createBitmap
import androidx.core.graphics.drawable.toBitmap
import androidx.core.graphics.withClip
import androidx.core.graphics.withTranslation
import androidx.palette.graphics.Palette
import coil3.ImageLoader
import coil3.request.ImageRequest
import coil3.request.allowHardware
import coil3.toBitmap
import com.lunara.app.R
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.math.roundToInt

/**
 * Draws the picture a share produces: an Instagram-story-sized card, the way Spotify wraps a song
 * before it goes out. Behind the cover sits a gradient pulled from the artwork itself, so two
 * songs never look the same, and a scannable square of the link sits at the foot for anyone who
 * would rather point a camera at it than type.
 *
 * Everything is drawn onto a plain [Canvas] rather than composed, because the result has to exist
 * as a PNG on disk that another app (Instagram, WhatsApp) can pick up - there is no view to
 * screenshot. The dimensions are the story ratio, 1080x1920, fixed so the output is identical on
 * every phone.
 */
object ShareStoryImage {

    private const val WIDTH = 1080
    private const val HEIGHT = 1920

    // Lunara's palette, matching the app theme. Used as the backdrop when the artwork has no
    // colour worth reading (a blank cover, or a failed load) so the card is never a grey void.
    private const val FALLBACK_TOP = 0xFF1ED760.toInt()
    private const val FALLBACK_BOTTOM = 0xFF0A2A16.toInt()
    private const val INK = 0xFFFFFFFF.toInt()
    private const val INK_SOFT = 0xE6FFFFFF.toInt()

    suspend fun create(
        context: Context,
        coverArtUrl: String?,
        title: String,
        artist: String,
        link: String,
        kindLabel: String,
    ): Bitmap =
        withContext(Dispatchers.Default) {
            val bitmap = createBitmap(WIDTH, HEIGHT)
            val canvas = Canvas(bitmap)

            var cover: Bitmap? = null
            if (!coverArtUrl.isNullOrBlank()) {
                cover =
                    runCatching {
                        val loader = ImageLoader(context)
                        val request =
                            ImageRequest
                                .Builder(context)
                                .data(coverArtUrl)
                                .size(WIDTH)
                                .allowHardware(false)
                                .build()
                        loader.execute(request).image?.toBitmap()
                    }.getOrNull()
            }

            drawBackdrop(canvas, cover)
            drawCover(canvas, cover)
            drawText(canvas, title, artist, kindLabel)
            drawFooter(canvas, context, link)

            bitmap
        }

    /** A diagonal gradient built from the cover's own colours, falling back to Lunara green. */
    private fun drawBackdrop(
        canvas: Canvas,
        cover: Bitmap?,
    ) {
        val paint = Paint().apply { isAntiAlias = true }
        val top: Int
        val bottom: Int
        if (cover != null) {
            val palette = Palette.from(cover).generate()
            val vibrant = palette.getVibrantColor(FALLBACK_TOP)
            val dark = palette.getDarkVibrantColor(palette.getDominantColor(FALLBACK_BOTTOM))
            top = vibrant
            bottom = darken(dark)
        } else {
            top = FALLBACK_TOP
            bottom = FALLBACK_BOTTOM
        }

        val shader =
            LinearGradient(
                0f,
                0f,
                WIDTH.toFloat(),
                HEIGHT.toFloat(),
                intArrayOf(top, bottom, 0xFF000000.toInt()),
                floatArrayOf(0f, 0.55f, 1f),
                Shader.TileMode.CLAMP,
            )
        paint.shader = shader
        canvas.drawRect(0f, 0f, WIDTH.toFloat(), HEIGHT.toFloat(), paint)
    }

    /** The artwork, large and centred, with a soft shadow so it lifts off the gradient. */
    private fun drawCover(
        canvas: Canvas,
        cover: Bitmap?,
    ) {
        val side = (WIDTH * 0.72f).roundToInt()
        val left = (WIDTH - side) / 2f
        val top = HEIGHT * 0.20f
        val radius = side * 0.08f
        val rect = RectF(left, top, left + side, top + side)

        val shadow = Paint().apply { isAntiAlias = true; color = 0x66000000 }
        canvas.drawRoundRect(RectF(rect).apply { inset(-18f, -18f) }, radius + 12f, radius + 12f, shadow)

        val clip = Path().apply { addRoundRect(rect, radius, radius, Path.Direction.CW) }
        canvas.withClip(clip) {
            if (cover != null) {
                val scaled = Bitmap.createScaledBitmap(cover, side, side, true)
                drawBitmap(scaled, null, rect, Paint().apply { isAntiAlias = true })
            } else {
                drawRect(rect, Paint().apply { color = 0xFF181818.toInt() })
            }
        }
    }

    private fun drawText(
        canvas: Canvas,
        title: String,
        artist: String,
        kindLabel: String,
    ) {
        val margin = WIDTH * 0.11f
        val textWidth = (WIDTH - margin * 2).roundToInt()
        val coverBottom = HEIGHT * 0.20f + (WIDTH * 0.72f)
        var y = coverBottom + HEIGHT * 0.05f

        // A small pill naming what is being shared: "SONG", "ALBUM", and so on.
        val pillPaint =
            TextPaint().apply {
                color = INK
                textSize = 34f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                letterSpacing = 0.25f
                isAntiAlias = true
            }
        val pillText = kindLabel.uppercase()
        val pillWidth = pillPaint.measureText(pillText) + 56f
        val pillRect = RectF(margin, y, margin + pillWidth, y + 64f)
        canvas.drawRoundRect(pillRect, 32f, 32f, Paint().apply { color = 0x33FFFFFF })
        canvas.drawText(pillText, margin + 28f, y + 44f, pillPaint)
        y += 64f + HEIGHT * 0.03f

        val safeTitle = title.ifBlank { "Unknown" }
        val titlePaint =
            TextPaint().apply {
                color = INK
                textSize = 76f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                isAntiAlias = true
            }
        val titleLayout =
            StaticLayout.Builder
                .obtain(safeTitle, 0, safeTitle.length, titlePaint, textWidth)
                .setAlignment(Layout.Alignment.ALIGN_NORMAL)
                .setMaxLines(3)
                .setEllipsize(android.text.TextUtils.TruncateAt.END)
                .build()
        canvas.withTranslation(margin, y) { titleLayout.draw(this) }
        y += titleLayout.height + 18f

        if (artist.isNotBlank()) {
            val artistPaint =
                TextPaint().apply {
                    color = INK_SOFT
                    textSize = 48f
                    isAntiAlias = true
                }
            val artistLayout =
                StaticLayout.Builder
                    .obtain(artist, 0, artist.length, artistPaint, textWidth)
                    .setAlignment(Layout.Alignment.ALIGN_NORMAL)
                    .setMaxLines(2)
                    .setEllipsize(android.text.TextUtils.TruncateAt.END)
                    .build()
            canvas.withTranslation(margin, y) { artistLayout.draw(this) }
        }
    }

    /** The Lunara mark and a scannable square of the link, pinned to the foot of the card. */
    private fun drawFooter(
        canvas: Canvas,
        context: Context,
        link: String,
    ) {
        val margin = WIDTH * 0.11f
        val footerTop = HEIGHT * 0.80f

        val qr = qrCode(link, 300)
        val qrSize = 240f
        val qrRect = RectF(margin, footerTop, margin + qrSize, footerTop + qrSize)
        // A white pad, without which a camera has nothing to read the dark modules against.
        canvas.drawRoundRect(RectF(qrRect).apply { inset(-20f, -20f) }, 28f, 28f, Paint().apply { color = INK })
        if (qr != null) {
            canvas.drawBitmap(qr, null, qrRect, Paint().apply { isAntiAlias = true })
        }

        // Wordmark to the right of the square.
        val textLeft = qrRect.right + 56f
        val namePaint =
            TextPaint().apply {
                color = INK
                textSize = 60f
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                letterSpacing = 0.05f
                isAntiAlias = true
            }
        val appName = context.getString(R.string.app_name)
        canvas.drawText(appName, textLeft, footerTop + 70f, namePaint)

        val tagPaint =
            TextPaint().apply {
                color = INK_SOFT
                textSize = 34f
                isAntiAlias = true
            }
        canvas.drawText("Listen on Lunara", textLeft, footerTop + 126f, tagPaint)
        canvas.drawText(prettyLink(link), textLeft, footerTop + 176f, tagPaint)

        // The app icon, small, bottom-right, as the last flourish.
        val icon =
            runCatching { ContextCompat.getDrawable(context, R.drawable.small_icon)?.toBitmap(96, 96) }.getOrNull()
        if (icon != null) {
            val iSize = 96f
            val iRect =
                RectF(WIDTH - margin - iSize, HEIGHT - margin - iSize, WIDTH - margin, HEIGHT - margin)
            canvas.drawBitmap(icon, null, iRect, Paint().apply { isAntiAlias = true })
        }
    }

    private fun prettyLink(link: String): String = link.removePrefix("https://").removePrefix("http://")

    private fun darken(color: Int): Int {
        val r = (color shr 16 and 0xFF) * 2 / 5
        val g = (color shr 8 and 0xFF) * 2 / 5
        val b = (color and 0xFF) * 2 / 5
        return (0xFF shl 24) or (r shl 16) or (g shl 8) or b
    }

    /** [text] as a square of black and white pixels, or null if it will not fit in one. */
    private fun qrCode(
        text: String,
        size: Int,
    ): Bitmap? =
        runCatching {
            val matrix =
                QRCodeWriter().encode(
                    text,
                    BarcodeFormat.QR_CODE,
                    size,
                    size,
                    mapOf(
                        EncodeHintType.MARGIN to 1,
                        EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.M,
                        EncodeHintType.CHARACTER_SET to "UTF-8",
                    ),
                )
            val pixels = IntArray(size * size)
            for (y in 0 until size) {
                val row = y * size
                for (x in 0 until size) {
                    pixels[row + x] = if (matrix[x, y]) 0xFF000000.toInt() else 0xFFFFFFFF.toInt()
                }
            }
            createBitmap(size, size).apply { setPixels(pixels, 0, size, 0, 0, size, size) }
        }.getOrNull()
}

