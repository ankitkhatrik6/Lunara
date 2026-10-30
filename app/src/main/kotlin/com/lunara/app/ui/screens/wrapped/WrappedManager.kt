/**
 * Ankit Khatri KC (C) 2026
 * Licensed under GPL-3.0
 */

package com.lunara.app.ui.screens.wrapped

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.lunara.innertube.YouTube
import com.lunara.innertube.models.AccountInfo
import com.lunara.app.constants.ArtistSongSortType
import com.lunara.app.db.DatabaseDao
import com.lunara.app.db.entities.Artist
import com.lunara.app.db.entities.PlaylistEntity
import com.lunara.app.db.entities.SongWithStats
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import timber.log.Timber
import java.io.File
import java.io.FileOutputStream
import java.time.LocalDateTime
import java.util.UUID

sealed class PlaylistCreationState {
    object Idle : PlaylistCreationState()
    object Creating : PlaylistCreationState()
    object Success : PlaylistCreationState()
}

class WrappedManager(
    private val databaseDao: DatabaseDao,
    private val context: Context
) {
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    private val _state = MutableStateFlow(WrappedState())
    val state = _state.asStateFlow()

    fun createPlaylist(imageResName: String, period: WrappedPeriod = WrappedPeriod.Weekly) {
        if (_state.value.playlistCreationState != PlaylistCreationState.Idle) return

        _state.update { it.copy(playlistCreationState = PlaylistCreationState.Creating) }
        scope.launch {
            try {
                withContext(Dispatchers.IO) {
                    val fromTimestamp = WrappedConstants.start(period)
                    val toTimestamp = WrappedConstants.end(period)
                    val allSongs = databaseDao.mostPlayedSongsStats(fromTimestamp, toTimeStamp = toTimestamp, limit = -1).first()

                    val playlistId = UUID.randomUUID().toString()

                    val drawableId = context.resources.getIdentifier(imageResName, "drawable", context.packageName)
                    val bitmap = BitmapFactory.decodeResource(context.resources, drawableId)
                    val file = File(context.cacheDir, "$playlistId.png")
                    FileOutputStream(file).use {
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
                    }

                    val newPlaylist = PlaylistEntity(
                        id = playlistId,
                        name = WrappedConstants.playlistName(period),
                        thumbnailUrl = file.toURI().toString(),
                        bookmarkedAt = LocalDateTime.now(),
                        isEditable = true
                    )
                    databaseDao.insert(newPlaylist)

                    val createdPlaylist = databaseDao.playlist(playlistId).first()
                    if (createdPlaylist != null) {
                        val songIds = allSongs.map { it.id to null }
                        databaseDao.addSongsToPlaylist(createdPlaylist, songIds)
                    } else {
                        Timber.tag("WrappedManager").e("Failed to create playlist $playlistId")
                    }
                    _state.update { it.copy(playlistCreationState = PlaylistCreationState.Success) }
                }
            } catch (e: Exception) {
                Timber.tag("WrappedManager").e(e, "Failed to create playlist")
                _state.update { it.copy(playlistCreationState = PlaylistCreationState.Idle) }
            }
        }
    }

    suspend fun prepare(period: WrappedPeriod = WrappedPeriod.Weekly) {
        if (_state.value.isDataReady && _state.value.period == period) return
        Timber.tag("WrappedManager").d("Starting Wrapped data preparation for $period")

        val fromTimestamp = WrappedConstants.start(period)
        val toTimestamp = WrappedConstants.end(period)

        withContext(Dispatchers.IO) {
            val accountInfoDeferred = async { YouTube.accountInfo().getOrNull() }
            val topSongsDeferred = async { databaseDao.mostPlayedSongsStats(fromTimestamp, toTimeStamp = toTimestamp, limit = 30).first() }
            val topArtistsDeferred = async { databaseDao.mostPlayedArtists(fromTimestamp, toTimeStamp = toTimestamp, limit = 5).first() }
            val uniqueSongCountDeferred = async { databaseDao.getUniqueSongCountInRange(fromTimestamp, toTimestamp).first() }
            val uniqueArtistCountDeferred = async { databaseDao.getUniqueArtistCountInRange(fromTimestamp, toTimestamp).first() }
            val totalPlayTimeMsDeferred = async { databaseDao.getTotalPlayTimeInRange(fromTimestamp, toTimestamp).first() ?: 0L }

            val results = awaitAll(
                accountInfoDeferred,
                topSongsDeferred,
                topArtistsDeferred,
                uniqueSongCountDeferred,
                uniqueArtistCountDeferred,
                totalPlayTimeMsDeferred
            )

            @Suppress("UNCHECKED_CAST")
            val topSongsResult = results[1] as List<SongWithStats>
            @Suppress("UNCHECKED_CAST")
            val topArtistsResult = results[2] as List<Artist>
            _state.update {
                it.copy(
                    accountInfo = results[0] as AccountInfo?,
                    period = period,
                    topSongs = topSongsResult,
                    topArtists = topArtistsResult,
                    uniqueSongCount = results[3] as Int,
                    uniqueArtistCount = results[4] as Int,
                    totalMinutes = (results[5] as Long) / 1000 / 60
                )
            }
        }

        generatePlaylistMap(period)
        _state.update { it.copy(isDataReady = true) }
        Timber.tag("WrappedManager").d("Wrapped data preparation finished for $period")
    }

    private fun generatePlaylistMap(period: WrappedPeriod) {
        // Weekly playlist map generation
        val topSongs = _state.value.topSongs
        val topArtists = _state.value.topArtists
        val trackMap = mutableMapOf<String, String>()

        if (topSongs.isNotEmpty()) {
            trackMap["WrappedScreenType.TopSongReveal"] = topSongs.first().id
            trackMap["WrappedScreenType.Top5Songs"] = topSongs.firstOrNull()?.id
            trackMap["WrappedScreenType.Playlist"] = topSongs.firstOrNull()?.id
        }
        if (topArtists.isNotEmpty()) {
            trackMap["WrappedScreenType.TopArtistReveal"] = topArtists.first().artist.id
            trackMap["WrappedScreenType.Top5Artists"] = topArtists.first().artist.id
        }
        trackMap["WrappedScreenType.Conclusion"] = "2-p9DM2Xvsc"

        _state.update { it.copy(trackMap = trackMap) }
    }

    fun dispose() {
        scope.cancel()
    }
}
