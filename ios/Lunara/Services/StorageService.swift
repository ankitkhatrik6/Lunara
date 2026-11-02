import Foundation

public final class StorageService: @unchecked Sendable {
    public static let shared = StorageService()
    
    private let likedKey = "lunara_liked_tracks_v1"
    private let playlistsKey = "lunara_user_playlists_v1"
    private let historyKey = "lunara_play_history_v1"
    private let speedDialKey = "lunara_speed_dial_v1"
    private let blockedArtistsKey = "lunara_blocked_artists_v1"
    private let downloadsKey = "lunara_downloads_v1"
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    public func getLikedTracks() -> [Track] {
        guard let data = defaults.data(forKey: likedKey),
              let tracks = try? JSONDecoder().decode([Track].self, from: data) else {
            return YouTubeMusicService.shared.sampleTracks.filter { $0.isLiked }
        }
        return tracks
    }
    
    public func saveLikedTracks(_ tracks: [Track]) {
        if let data = try? JSONEncoder().encode(tracks) {
            defaults.set(data, forKey: likedKey)
        }
    }
    
    public func toggleLike(track: Track) -> Bool {
        var tracks = getLikedTracks()
        let isNowLiked: Bool
        if let idx = tracks.firstIndex(where: { $0.id == track.id }) {
            tracks.remove(at: idx)
            isNowLiked = false
        } else {
            var updated = track
            updated.isLiked = true
            tracks.insert(updated, at: 0)
            isNowLiked = true
        }
        saveLikedTracks(tracks)
        return isNowLiked
    }
    
    public func isTrackLiked(id: String) -> Bool {
        getLikedTracks().contains(where: { $0.id == id })
    }
    
    public func getPlaylists() -> [Playlist] {
        guard let data = defaults.data(forKey: playlistsKey),
              let playlists = try? JSONDecoder().decode([Playlist].self, from: data) else {
            return [
                Playlist(id: "fav_mix", title: "Daily Mix 1", authorName: "Made for You", artworkUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80", trackCount: 25),
                Playlist(id: "deep_focus", title: "Deep Focus", authorName: "Lunara Editorial", artworkUrl: "https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=500&q=80", trackCount: 50),
                Playlist(id: "top_hits", title: "Global Top Hits", authorName: "Trending", artworkUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80", trackCount: 40)
            ]
        }
        return playlists
    }
    
    public func isHighQualityAudioEnabled() -> Bool {
        defaults.bool(forKey: highQualityAudioKey)
    }
    
    public func setHighQualityAudio(enabled: Bool) {
        defaults.set(enabled, forKey: highQualityAudioKey)
    }

    // MARK: - Playlists

    public func savePlaylists(_ playlists: [Playlist]) {
        if let data = try? JSONEncoder().encode(playlists) {
            defaults.set(data, forKey: playlistsKey)
        }
    }

    public func createPlaylist(title: String, artworkUrl: String? = nil) {
        var playlists = getPlaylists()
        let newPlaylist = Playlist(
            id: UUID().uuidString,
            title: title,
            authorName: "You",
            artworkUrl: artworkUrl ?? "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&q=80",
            trackCount: 0
        )
        playlists.insert(newPlaylist, at: 0)
        savePlaylists(playlists)
    }

    public func addTrackToPlaylist(track: Track, playlistId: String) {
        var playlists = getPlaylists()
        guard let idx = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        playlists[idx].tracks.append(track)
        playlists[idx].trackCount = playlists[idx].tracks.count
        savePlaylists(playlists)
    }
    }

    // MARK: - Play History

    public func getPlayHistory() -> [PlayHistoryItem] {
        guard let data = defaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([PlayHistoryItem].self, from: data) else {
            return []
        }
        return history.sorted { $0.playedAt > $1.playedAt }
    }

    public func addToPlayHistory(track: Track) {
        var history = getPlayHistory()
        history.removeAll { $0.track.id == track.id }
        history.insert(PlayHistoryItem(track: track), at: 0)
        if history.count > 500 { history = Array(history.prefix(500)) }
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: historyKey)
        }
    }

    public func clearPlayHistory() {
        defaults.removeObject(forKey: historyKey)
    }

    // MARK: - Speed Dial

    public func getSpeedDial() -> [SpeedDialItem] {
        guard let data = defaults.data(forKey: speedDialKey),
              let items = try? JSONDecoder().decode([SpeedDialItem].self, from: data) else {
            return []
        }
        return items
    }

    public func addSpeedDial(item: SpeedDialItem) {
        var items = getSpeedDial()
        items.append(item)
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: speedDialKey)
        }
    }

    public func removeSpeedDial(id: UUID) {
        var items = getSpeedDial()
        items.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: speedDialKey)
        }
    }

    // MARK: - Blocked Artists

    public func getBlockedArtists() -> [BlockedArtist] {
        guard let data = defaults.data(forKey: blockedArtistsKey),
              let artists = try? JSONDecoder().decode([BlockedArtist].self, from: data) else {
            return []
        }
        return artists
    }

    public func blockArtist(_ artist: BlockedArtist) {
        var artists = getBlockedArtists()
        if !artists.contains(where: { $0.id == artist.id }) {
            artists.append(artist)
            if let data = try? JSONEncoder().encode(artists) {
                defaults.set(data, forKey: blockedArtistsKey)
            }
        }
    }

    public func unblockArtist(id: String) {
        var artists = getBlockedArtists()
        artists.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(artists) {
            defaults.set(data, forKey: blockedArtistsKey)
        }
    }

    public func isArtistBlocked(id: String) -> Bool {
        getBlockedArtists().contains { $0.id == id }
    }

    // MARK: - Downloads

    public func getDownloads() -> [DownloadItem] {
        guard let data = defaults.data(forKey: downloadsKey),
              let downloads = try? JSONDecoder().decode([DownloadItem].self, from: data) else {
            return []
        }
        return downloads
    }

    public func addDownload(track: Track) {
        var downloads = getDownloads()
        if !downloads.contains(where: { $0.track.id == track.id }) {
            downloads.append(DownloadItem(track: track))
            if let data = try? JSONEncoder().encode(downloads) {
                defaults.set(data, forKey: downloadsKey)
            }
        }
    }

    public func removeDownload(trackId: String) {
        var downloads = getDownloads()
        downloads.removeAll { $0.track.id == trackId }
        if let data = try? JSONEncoder().encode(downloads) {
            defaults.set(data, forKey: downloadsKey)
        }
    }

    public func isDownloaded(trackId: String) -> Bool {
        getDownloads().contains { $0.track.id == trackId }
    }
}

