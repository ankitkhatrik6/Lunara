/**
 * Ankit Khatri KC (C) 2026
 * Licensed under GPL-3.0
 *
 * Lunara Wrapped tab: a beautiful home for your weekly, monthly and yearly
 * listening recaps. Shows real play counts from your playback history and lets
 * you share each recap as an Instagram-style story image.
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
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.lunara.app.R
import com.lunara.app.viewmodels.YoursViewModel
import com.lunara.app.ui.theme.SpotifyCardSurface
import com.lunara.app.ui.theme.SpotifyDivider
import com.lunara.app.ui.theme.SpotifyGreen
import com.lunara.app.ui.theme.SpotifyTextPrimary
import com.lunara.app.ui.theme.SpotifyTextSecondary
import kotlinx.coroutines.launch

private const val STORY_WIDTH = 1080
private const val STORY_HEIGHT = 1920

/** Renders the Wrapped tab stats to a story-sized PNG and shares it via the system chooser. */
object WrappedTabShare {
    fun share(host: Activity, weekly: Int, monthly: Int, yearly: Int) {
        val file = java.io.File(host.cacheDir, "lunara_wrapped_tab_story.png")
        val bitmap = renderStoryToBitmap(host, weekly, monthly, yearly)
        java.io.FileOutputStream(file).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 92, out)
        }
        bitmap.recycle()

        val uri = androidx.core.content.FileProvider.getUriForFile(
            host,
            "${host.packageName}.FileProvider",
            file,
        )
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        }
        host.startActivity(Intent.createChooser(intent, host.getString(R.string.wrapped_story_share)))
    }

    private fun renderStoryToBitmap(context: Context, weekly: Int, monthly: Int, yearly: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(STORY_WIDTH, STORY_HEIGHT, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Background
        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#121212") }
        canvas.drawRect(0f, 0f, STORY_WIDTH.toFloat(), STORY_HEIGHT.toFloat(), bgPaint)

        // Header
        val headerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = 64f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(stringResource(R.string.lunara_wrapped_title), STORY_WIDTH / 2f, 200f, headerPaint)

        // Subtitle
        val subPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#B3B3B3")
            textSize = 32f
            typeface = Typeface.DEFAULT
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(stringResource(R.string.wrapped_story_subtitle).format("year"), STORY_WIDTH / 2f, 280f, subPaint)

        // Stat cards
        val cardWidth = 280f
        val cardHeight = 300f
        val spacing = 40f
        val startX = (STORY_WIDTH - (cardWidth * 3 + spacing * 2)) / 2f

        val stats = listOf(
            Pair(stringResource(R.string.wrapped_period_weekly), weekly),
            Pair(stringResource(R.string.wrapped_period_monthly), monthly),
            Pair(stringResource(R.string.wrapped_period_yearly), yearly),
        )

        val cardPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#1E1E1E")
        }

        val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#B3B3B3")
            textSize = 36f
            typeface = Typeface.DEFAULT
            textAlign = Paint.Align.CENTER
        }

        val countPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textSize = 64f
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
        }

        for ((i, (label, count)) in stats.withIndex()) {
            val cx = startX + i * (cardWidth + spacing) + cardWidth / 2f
            val cy = 500f

            // Card background
            canvas.drawRoundRect(
                cx - cardWidth / 2f, cy - cardHeight / 2f,
                cx + cardWidth / 2f, cy + cardHeight / 2f,
                32f, 32f, cardPaint
            )

            // Label
            canvas.drawText(label, cx, cy - 60f, labelPaint)

            // Count
            canvas.drawText(count.toString(), cx, cy + 20f, countPaint)
        }

        return bitmap
    }
}

/**
 * The Wrapped tab screen. Shows weekly, monthly and yearly listening recaps
 * computed from real playback history, with an Instagram-style story share.
 */
@Composable
fun WrappedTabScreen(
    navController: androidx.navigation.NavController,
) {
    val viewModel: YoursViewModel = hiltViewModel()
    val context = LocalContext.current

    val wrappedStats by viewModel.wrappedStats.collectAsStateWithLifecycle(
        initialValue = WrappedStats(),
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = stringResource(R.string.lunara_wrapped_title),
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.weight(1f),
            )
            IconButton(
                onClick = {
                    val activity = context as? Activity
                    if (activity != null) {
                        WrappedTabShare.share(
                            activity,
                            wrappedStats.weeklyPlayCount,
                            wrappedStats.monthlyPlayCount,
                            wrappedStats.yearlyPlayCount,
                        )
                    }
                },
            ) {
                Icon(
                    painter = painterResource(R.drawable.share),
                    contentDescription = stringResource(R.string.wrapped_share_story),
                    tint = MaterialTheme.colorScheme.primary,
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
        ) {
            WrappedRecapCard(
                period = stringResource(R.string.wrapped_period_weekly),
                count = wrappedStats.weeklyPlayCount,
                icon = R.drawable.trending_up,
                color = Color(0xFFFFA88B),
            )
            Spacer(modifier = Modifier.height(12.dp))
            WrappedRecapCard(
                period = stringResource(R.string.wrapped_period_monthly),
                count = wrappedStats.monthlyPlayCount,
                icon = R.drawable.trending_up,
                color = Color(0xFF7AD7F0),
            )
            Spacer(modifier = Modifier.height(12.dp))
            WrappedRecapCard(
                period = stringResource(R.string.wrapped_period_yearly),
                count = wrappedStats.yearlyPlayCount,
                icon = R.drawable.trending_up,
                color = Color(0xFF5138AC),
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        if (wrappedStats.weeklyPlayCount == 0 && wrappedStats.monthlyPlayCount == 0 && wrappedStats.yearlyPlayCount == 0) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Icon(
                    painter = painterResource(R.drawable.stats),
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(48.dp),
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = stringResource(R.string.wrapped_no_data),
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = stringResource(R.string.wrapped_story_subtitle).format("listening"),
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

/**
 * A single recap card showing a period label, play count and a descriptive message.
 */
@Composable
private fun WrappedRecapCard(
    period: String,
    count: Int,
    @androidx.annotation.DrawableRes icon: Int,
    color: Color,
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = androidx.compose.material3.CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
        ),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                painter = painterResource(icon),
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(32.dp),
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = period,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface,
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = if (count > 0) "$count ${stringResource(R.string.wrapped_story_minutes_label).lowercase()}" else stringResource(R.string.wrapped_no_data),
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Text(
                text = if (count > 0) count.toString() else "–",
                fontSize = 32.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary,
            )
        }
    }
}
