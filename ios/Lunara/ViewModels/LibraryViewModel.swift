import SwiftUI
import Observation

public enum LibraryFilter: String, CaseIterable {
    case playlists = "Playlists"
    case artists = "Artists"
    case albums = "Albums"
    case downloaded = "Downloaded"
}

@Observable
@MainActor
public final class LibraryViewModel {
    public var selectedFilter: LibraryFilter = .playlists
    public var likedTracks: [Track] = []
    public var playlists: [Playlist] = []
    public var isCreatePlaylistPresented: Bool = false
    public var newPlaylistTitle: String = ""
    
    private let storage = StorageService.shared
    
    public init() {
        loadLibrary()
    }
    
    public func loadLibrary() {
        self.likedTracks = storage.getLikedTracks()
        self.playlists = storage.getPlaylists()
    }
    
    public func createPlaylist() {
        let trimmed = newPlaylistTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let newPlaylist = Playlist(
            id: UUID().uuidString,
            title: trimmed,
            authorName: "You",
            artworkUrl: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&q=80",
            trackCount: 0
        )
        playlists.insert(newPlaylist, at: 0)
        newPlaylistTitle = ""
        isCreatePlaylistPresented = false
    }
}
