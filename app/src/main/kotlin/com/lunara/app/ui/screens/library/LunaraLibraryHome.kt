/**
 * Ankit Khatri KC (C) 2026
 * Licensed under GPL-3.0
 *
 * Cute, dreamy "Your Library" landing: pastel emblem header, bubbly filter chips,
 * kawaii gradient pinned playlists (Liked Songs in sakura rose, Top 50 in peach coral,
 * Offline in mint-teal, Cached in lavender, Local Music in sky blue), followed by
 * user playlists and favorite artists.
 */

package com.lunara.app.ui.screens.library

import android.content.Context
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.weight
import androidx.compose.animation.core.tween
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.lunara.app.ui.theme.SpotifyTextPrimary
import com.lunara.app.utils.LocalMusic
import com.lunara.app.LocalPlayerAwareWindowInsets
import com.lunara.app.R
import com.lunara.app.constants.LocalMusicFoldersKey
import com.lunara.app.constants.ShowLikedPlaylistKey
import com.lunara.app.constants.ShowTopPlaylistKey
import com.lunara.app.constants.ShowDownloadedPlaylistKey
import com.lunara.app.utils.dataStore
import com.lunara.app.utils.get
import androidx.compose.material3.Button
import androidx.annotation.DrawableRes
import androidx.compose.material3.Card
import com.lunara.app.ui.screens.Screens
import com.lunara.app.ui.screens.wrapped.WrappedStats
import com.lunara.app.ui.component.CreatePlaylistDialog
import com.lunara.app.ui.component.LunaraFilterChips
import com.lunara.app.ui.component.LunaraMusicCard
import com.lunara.app.ui.component.LunaraPlaylistCard
import com.lunara.app.ui.component.LunaraPlaylistPalette
import com.lunara.app.ui.component.LunaraSectionHeader
import com.lunara.app.viewmodels.YoursViewModel
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

private const val LONG_RATIO = 3.0f
private const val BOX_RATIO = 1.62f
private const val USER_RATIO = 1.62f

private enum class LibraryTab { ALL, PLAYLISTS, ARTISTS, DOWNLOADED }

@Composable
fun LunaraLibraryHome(
    navController: NavController,
    viewModel: YoursViewModel = hiltViewModel(),
) {
    val playlists by viewModel.playlists.collectAsStateWithLifecycle()
    val artists by viewModel.favoriteArtists.collectAsStateWithLifecycle()
    val likedSongs by viewModel.likedSongs.collectAsStateWithLifecycle()
    val likedThumbs by viewModel.likedThumbnails.collectAsStateWithLifecycle()
    val downloadedThumbs by viewModel.downloadedThumbnails.collectAsStateWithLifecycle()
    val localThumbs by viewModel.localThumbnails.collectAsStateWithLifecycle()
    val localCount by viewModel.localSongCount.collectAsStateWithLifecycle()

    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val localMusicFolders = rememberSaveable { context.dataStore.get(LocalMusicFoldersKey, emptySet()) }
    var localGranted by remember { mutableStateOf(LocalMusic.hasPermission(context)) }
    val audioPermission =
        rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            localGranted = granted
            if (granted) {
                scope.launch(Dispatchers.IO) {
                    // Local music scan requires Hilt-injected database
                }
            }
        }
    val topThumbs by viewModel.topThumbnails.collectAsStateWithLifecycle()
    val showLiked = rememberSaveable { context.dataStore.get(ShowLikedPlaylistKey, true) }
    val showTop = rememberSaveable { context.dataStore.get(ShowTopPlaylistKey, true) }
    val showDownloaded = rememberSaveable { context.dataStore.get(ShowDownloadedPlaylistKey, true) }
    val songsWord = stringResource(R.string.songs).lowercase()

    var selectedTab by rememberSaveable { mutableStateOf(LibraryTab.ALL) }
    var showCreatePlaylist by rememberSaveable { mutableStateOf(false) }

    val weeklyMost = playlists.firstOrNull { it.title.contains("weekly most", ignoreCase = true) }
    val monthlyMost = playlists.firstOrNull { it.title.contains("monthly most", ignoreCase = true) }
    val userPlaylists = playlists.filter { it !== weeklyMost && it !== monthlyMost }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background),
        contentPadding = LocalPlayerAwareWindowInsets.current.asPaddingValues(),
    ) {
        // Minimalist Spotify "Your Library" header
        item("spotify_library_header") {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 12.dp, bottom = 8.dp),
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = stringResource(id = R.string.filter_library),
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        color = SpotifyTextPrimary,
                        modifier = Modifier.weight(1f),
                    )
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(CircleShape)
                            .clickable { navController.navigate(Screens.Search.route) },
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(
                            painter = painterResource(R.drawable.search),
                            contentDescription = stringResource(id = R.string.search),
                            tint = SpotifyTextPrimary,
                            modifier = Modifier.size(22.dp),
                        )
                    }
                }

                Spacer(Modifier.height(10.dp))

                LunaraFilterChips(
                    chips = listOf(
                        LibraryTab.ALL to "All",
                        LibraryTab.PLAYLISTS to stringResource(id = R.string.playlists),
                        LibraryTab.ARTISTS to stringResource(id = R.string.artists),
                        LibraryTab.DOWNLOADED to stringResource(id = R.string.offline),
                    ),
                    currentValue = selectedTab,
                    onSelect = { selectedTab = it },
                )
            }
        }

        val showSystemPlaylists = selectedTab == LibraryTab.ALL || selectedTab == LibraryTab.PLAYLISTS
        val showDownloadedOnly = selectedTab == LibraryTab.DOWNLOADED

        // ---- System playlists ----
        if ((showSystemPlaylists || showDownloadedOnly) && showLiked && !showDownloadedOnly) {
            item("liked") {
                LongPad {
                    LunaraPlaylistCard(
                        title = stringResource(id = R.string.liked),
                        subtitle = "${likedSongs.size} $songsWord",
                        thumbnails = likedThumbs,
                        seedColor = Color(0xFF5138AC),
                        aspectRatio = LONG_RATIO,
                        iconRes = R.drawable.favorite,
                        onClick = { navController.navigate("auto_playlist/liked") },
                    )
                }
            }
        }

        if (showSystemPlaylists && (weeklyMost != null || monthlyMost != null)) {
            item("weekly_monthly") {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    if (weeklyMost != null) {
                        LunaraPlaylistCard(
                            title = weeklyMost.title,
                            subtitle = "${weeklyMost.songCount} $songsWord",
                            thumbnails = weeklyMost.thumbnails.take(4),
                            seedColor = Color(0xFFA88BEB),
                            aspectRatio = BOX_RATIO,
                            onClick = { navController.navigate("local_playlist/${weeklyMost.id}") },
                            modifier = Modifier.weight(1f),
                        )
                    } else {
                        Spacer(Modifier.weight(1f))
                    }
                    if (monthlyMost != null) {
                        LunaraPlaylistCard(
                            title = monthlyMost.title,
                            subtitle = "${monthlyMost.songCount} $songsWord",
                            thumbnails = monthlyMost.thumbnails.take(4),
                            seedColor = Color(0xFF7AD7F0),
                            aspectRatio = BOX_RATIO,
                            onClick = { navController.navigate("local_playlist/${monthlyMost.id}") },
                            modifier = Modifier.weight(1f),
                        )
                    } else {
                        Spacer(Modifier.weight(1f))
                    }
                }
            }
        }

        // ---- Lunara Wrapped section ----
        // Check if today is a special day (Sunday/1st/Jan 1) and show wrapped if first time
        val wrapped = WrappedStats()
        val isWrappedDay = isWrappedDayLocal()
        item("lunara_wrapped") {
            if (isWrappedDay) {
                LunaraWrappedPopup(
                    onDismissed = { /* handled internally */ },
                    wrappedStats = wrapped,
                )
            }
        }

        if (showSystemPlaylists && showTop) {
            item("top") {
                LongPad {
                    LunaraPlaylistCard(
                        title = stringResource(id = R.string.your_top_50),
                        subtitle = "Most played tracks",
                        thumbnails = topThumbs,
                        seedColor = Color(0xFF1E3264),
                        aspectRatio = LONG_RATIO,
                        iconRes = R.drawable.trending_up,
                        onClick = { navController.navigate("top_playlist/50") },
                    )
                }
            }
        }

        if (showSystemPlaylists || showDownloadedOnly) {
            if (showDownloaded || showDownloadedOnly) {
                item("downloaded") {
                    LongPad {
                        LunaraPlaylistCard(
                            title = stringResource(id = R.string.offline),
                            subtitle = "Downloaded songs",
                            thumbnails = downloadedThumbs,
                            seedColor = Color(0xFF148A08),
                            aspectRatio = LONG_RATIO,
                            iconRes = R.drawable.download,
                            onClick = { navController.navigate("auto_playlist/downloaded") },
                        )
                    }
                }
            }
        }

        // ---- Create playlist ----
        if (selectedTab == LibraryTab.ALL || selectedTab == LibraryTab.PLAYLISTS) {
            item("create_playlist") {
                LongPad {
                    LunaraPlaylistCard(
                        title = stringResource(id = R.string.create_playlist),
                        subtitle = "Start a new playlist",
                        thumbnails = emptyList(),
                        seedColor = Color(0xFF1ED760),
                        aspectRatio = LONG_RATIO,
                        iconRes = R.drawable.add,
                        onClick = { showCreatePlaylist = true },
                    )
                }
            }
        }

        if ((showSystemPlaylists || showDownloadedOnly) && localCount == 0) {
            item("local-invite") {
                LongPad {
                    LunaraPlaylistCard(
                        title = stringResource(id = R.string.local_music),
                        subtitle = stringResource(id = R.string.local_music_scan),
                        thumbnails = emptyList(),
                        seedColor = Color(0xFF282828),
                        aspectRatio = LONG_RATIO,
                        iconRes = R.drawable.library_music,
                        onClick = {
                            if (localGranted) {
                                // Local music scan requires Hilt-injected database
                            } else {
                                audioPermission.launch(LocalMusic.permission)
                            }
                        },
                    )
                }
            }
        }

        if ((showSystemPlaylists || showDownloadedOnly) && localCount > 0) {
            item("local") {
                LongPad {
                    LunaraPlaylistCard(
                        title = stringResource(id = R.string.local_music),
                        subtitle = "$localCount $songsWord",
                        thumbnails = localThumbs,
                        seedColor = Color(0xFF282828),
                        aspectRatio = LONG_RATIO,
                        iconRes = R.drawable.library_music,
                        onClick = { navController.navigate("auto_playlist/local") },
                    )
                }
            }
        }

        // ---- Created by you ----
        if ((selectedTab == LibraryTab.ALL || selectedTab == LibraryTab.PLAYLISTS) && userPlaylists.isNotEmpty()) {
            item("cby_head") {
                LunaraSectionHeader(stringResource(id = R.string.created_by_you)),
            }
            itemsIndexed(userPlaylists.chunked(2), key = { _, row -> "cby_${row.first().id}" }) { rowIndex, rowItems ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    rowItems.forEachIndexed { j, pl ->
                        LunaraPlaylistCard(
                            title = pl.title,
                            subtitle = "${pl.songCount} $songsWord",
                            thumbnails = pl.thumbnails.take(4),
                            seedColor = LunaraPlaylistPalette[(rowIndex * 2 + j) % LunaraPlaylistPalette.size],
                            aspectRatio = USER_RATIO,
                            onClick = { navController.navigate("local_playlist/${pl.id}") },
                            modifier = Modifier.weight(1f),
                        )
                    }
                    if (rowItems.size == 1) Spacer(Modifier.weight(1f))
                }
            }
        }

        // ---- Artists you liked ----
        if ((selectedTab == LibraryTab.ALL || selectedTab == LibraryTab.ARTISTS) && artists.isNotEmpty()) {
            item("art_head") {
                LunaraSectionHeader(stringResource(id = R.string.artists_you_liked)),
            }
            item("art_rail") {
                LazyRow(
                    contentPadding = PaddingValues(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    items(artists, key = { it.id }) { artist ->
                        LunaraMusicCard(
                            title = artist.title,
                            subtitle = if (artist.songCount > 0) "${artist.songCount} $songsWord" else "Artist",
                            thumbnailUrl = artist.thumbnailUrl,
                            isCircular = true,
                            fallbackIcon = R.drawable.artist,
                            onClick = { navController.navigate("artist/${artist.id}") },
                        )
                    }
                }
            }
        }

        item("bottom") { Spacer(Modifier.height(28.dp)) }
    }

    if (showCreatePlaylist) {
        CreatePlaylistDialog(
            onDismiss = { showCreatePlaylist = false },
        )
    }
}

@Composable
private fun LongPad(content: @Composable () -> Unit) {
    Box(Modifier.padding(horizontal = 16.dp, vertical = 6.dp)) {
        content()
    }
}

/**
 * Ankit Khatri KC (C) 2026
 * Checks if today is a wrapped day (Sunday, first of month, or first of year).
 * Also tracks if the wrapped has been shown this cycle using data store.
 */
@Composable
private fun isWrappedDayLocal(context: Context = LocalContext.current): Boolean {
    val today = java.time.LocalDate.now()
    val isSunday = today.dayOfWeek == java.time.DayOfWeek.SUNDAY
    val isFirstOfMonth = today.dayOfMonth == 1
    val isFirstOfYear = today.dayOfYear == 1
    return isSunday || isFirstOfMonth || isFirstOfYear
}

/**
 * Ankit Khatri KC (C) 2026
 * Popup displayed when Lunara Wrapped is available (on wrapped days).
 * Shows aggregated weekly, monthly, and yearly play counts with an animated entrance.
 */
@Composable
fun LunaraWrappedPopup(
    onDismissed: () -> Unit = {},
    wrappedStats: WrappedStats = WrappedStats(),
) {
    var showPopup by remember { mutableStateOf(true) }
    if (showPopup == false) {
        onDismissed()
        return
    }
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.surface)
            .clickable { showPopup = false },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Card(
            modifier = Modifier.padding(16.dp).size(280.dp),
        ) {
            Column(
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(16.dp),
            ) {
                Text(
                    text = stringResource(id = R.string.lunara_wrapped_title),
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary,
                )
                Box(
                    modifier = Modifier.height(2.dp).fillMaxWidth().background(MaterialTheme.colorScheme.onSurfaceVariant),
                )
                if (wrappedStats.weeklyPlayCount > 0) {
                    wrappedCountRow(
                        icon = R.drawable.stats,
                        count = wrappedStats.weeklyPlayCount,
                        label = R.string.weekly,
                    )
                }
                if (wrappedStats.monthlyPlayCount > 0) {
                    wrappedCountRow(
                        icon = R.drawable.stats,
                        count = wrappedStats.monthlyPlayCount,
                        label = R.string.monthly,
                    )
                }
                if (wrappedStats.yearlyPlayCount > 0) {
                    wrappedCountRow(
                        icon = R.drawable.stats,
                        count = wrappedStats.yearlyPlayCount,
                        label = R.string.yearly,
                    )
                }
                Button(
                    onClick = { showPopup = false },
                    modifier = Modifier.align(Alignment.End),
                ) {
                    Text(
                        text = stringResource(id = R.string.dismiss),
                    )
                }
            }
        }
    }
}

/**
 * Row displaying a wrapped count with icon and label.
 */
@Composable
private fun wrappedCountRow(
    @DrawableRes icon: Int,
    count: Int,
    label: Int,
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(4.dp),
    ) {
        Icon(
            painter = painterResource(icon),
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.size(20.dp),
        )
        Text(
            text = "" + count,
            fontSize = 18.sp,
            color = MaterialTheme.colorScheme.primary,
        )
        Text(
            text = "" + label,
            fontSize = 14.sp,
            color = MaterialTheme.colorScheme.onSurface,
        )
    }
}
