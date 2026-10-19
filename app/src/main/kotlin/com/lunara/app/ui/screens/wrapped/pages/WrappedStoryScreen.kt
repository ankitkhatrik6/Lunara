/**
 * Ankit Khatri KC (C) 2026
 * Metrolist Project (C) 2026
 * Licensed under GPL-3.0
 */

package com.lunara.app.ui.screens.wrapped.pages

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import com.lunara.app.R
import com.lunara.app.ui.screens.wrapped.WrappedConstants
import com.lunara.app.ui.screens.wrapped.WrappedState
import com.lunara.app.ui.theme.bbh_bartle

@Composable
fun WrappedStoryScreen(
    state: WrappedState,
    onShare: () -> Unit,
    onClose: () -> Unit
) {
    val topSong = state.topSongs.firstOrNull()
    val topArtist = state.topArtists.firstOrNull()
    val topAlbum = state.topAlbum

    Box(modifier = Modifier.fillMaxSize()) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF121212))
        )
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .padding(bottom = 16.dp)
                    .wrapContentWidth()
                    .align(Alignment.CenterHorizontally)
            ) {
                Text(
                    text = WrappedConstants.periodLabel(state.period).uppercase(),
                    style = TextStyle(
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary,
                        textAlign = TextAlign.Center,
                        letterSpacing = 1.2.sp
                    )
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = stringResource(R.string.wrapped_story_header),
                style = TextStyle(
                    fontFamily = bbh_bartle,
                    fontSize = 34.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    textAlign = TextAlign.Center
                )
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = stringResource(R.string.wrapped_story_subtitle, WrappedConstants.periodLabel(state.period)),
                style = TextStyle(
                    fontSize = 15.sp,
                    color = Color.White.copy(alpha = 0.7f),
                    textAlign = TextAlign.Center
                )
            )
            Spacer(modifier = Modifier.height(32.dp))
            Box(
                modifier = Modifier
                    .width(220.dp)
                    .align(Alignment.CenterHorizontally)
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = state.totalMinutes.toString(),
                        style = TextStyle(
                            fontFamily = bbh_bartle,
                            fontSize = 64.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    )
                    Text(
                        text = stringResource(R.string.wrapped_story_minutes_label),
                        style = TextStyle(
                            fontSize = 14.sp,
                            color = Color.White.copy(alpha = 0.6f)
                        )
                    )
                }
            }
            Spacer(modifier = Modifier.height(32.dp))
            topSong?.let { song ->
                StoryStatRow(
                    label = stringResource(R.string.wrapped_story_top_song),
                    value = song.title.ifBlank { "Unknown track" },
                    subtitle = song.artists.joinToString(" ${stringResource(R.string.and)} ") { it.name }
                        .ifBlank { song.artistName.orEmpty() },
                    imageUrl = song.thumbnailUrl
                )
            }
            Spacer(modifier = Modifier.height(16.dp))
            topArtist?.let { artist ->
                StoryStatRow(
                    label = stringResource(R.string.wrapped_story_top_artist),
                    value = artist.title.ifBlank { "Unknown artist" },
                    subtitle = stringResource(R.string.wrapped_story_listened_to, state.uniqueArtistCount),
                    imageUrl = null
                )
            }
            Spacer(modifier = Modifier.height(16.dp))
            topAlbum?.let { album ->
                StoryStatRow(
                    label = stringResource(R.string.wrapped_story_top_album),
                    value = album.title.ifBlank { "Unknown album" },
                    subtitle = album.artists.joinToString(" ${stringResource(R.string.and)} ") { it.name }
                        .ifBlank { "" },
                    imageUrl = album.thumbnailUrl
                )
            }
            Spacer(modifier = Modifier.height(40.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 40.dp),
                contentAlignment = Alignment.Center
            ) {
                TextButton(
                    onClick = onClose,
                    modifier = Modifier.width(90.dp)
                ) {
                    Text(
                        text = stringResource(R.string.wrapped_story_close),
                        style = TextStyle(
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White.copy(alpha = 0.8f)
                        )
                    )
                }
                Spacer(modifier = Modifier.width(24.dp))
                TextButton(
                    onClick = onShare,
                    modifier = Modifier.width(90.dp)
                ) {
                    Text(
                        text = stringResource(R.string.wrapped_story_share),
                        style = TextStyle(
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    )
                }
            }
        }
    }
}

@Composable
private fun StoryStatRow(
    label: String,
    value: String,
    subtitle: String,
    imageUrl: String?
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        imageUrl?.let { url ->
            AsyncImage(
                model = url,
                contentDescription = null,
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(6.dp)),
                contentScale = ContentScale.Crop
            )
            Spacer(modifier = Modifier.width(12.dp))
        }
        Column {
            Text(
                text = label,
                style = TextStyle(
                    fontSize = 13.sp,
                    color = Color.White.copy(alpha = 0.5f)
                )
            )
            Text(
                text = value,
                style = TextStyle(
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    maxLines = 1
                )
            )
            if (subtitle.isNotBlank()) {
                Text(
                    text = subtitle,
                    style = TextStyle(
                        fontSize = 13.sp,
                        color = Color.White.copy(alpha = 0.7f),
                        maxLines = 1
                    )
                )
            }
        }
    }
}

@Composable
private fun TextButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    androidx.compose.material3.TextButton(
        onClick = onClick,
        modifier = modifier
    ) {
        content()
    }
}
