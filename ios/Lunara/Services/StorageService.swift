import Foundation

public final class StorageService: @unchecked Sendable {
    public static let shared = StorageService()
    
    private let likedKey = "lunara_liked_tracks_v1"
    private let playlistsKey = "lunara_user_playlists_v1"
    private let highQualityAudioKey = "lunara_high_quality_audio"
    
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
}
