import SwiftUI
import Observation

public enum HomeFilterCategory: String, CaseIterable {
    case all = "All"
    case music = "Music"
}

@Observable
@MainActor
public final class HomeViewModel {
    public var selectedCategory: HomeFilterCategory = .all
    public var quickAccessTracks: [Track] = []
    public var recentlyPlayed: [Track] = []
    public var recommendedAlbums: [Album] = []
    public var trendingHits: [Track] = []
    public var likedTracks: [Track] = []
    public var homeFeed: HomeFeed = .empty
    public var isLoading: Bool = false

    public init() {
        loadData()
    }

    public var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    public func loadData() {
        isLoading = true
        Task {
            await loadHomeFeed()
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    private func loadHomeFeed() async {
        let feed = await YouTubeMusicService.shared.fetchHome()
        await MainActor.run {
            self.homeFeed = feed
            self.quickAccessTracks = feed.sections
                .filter { $0.isSongs }
                .flatMap { $0.items }
                .prefix(6)
                .map { $0.asTrack }
            self.recentlyPlayed = feed.sections
                .filter { !$0.isSongs }
                .flatMap { $0.items }
                .prefix(10)
                .map { $0.asTrack }
            self.trendingHits = feed.sections
                .flatMap { $0.items }
                .prefix(10)
                .map { $0.asTrack }
            self.likedTracks = StorageService.shared.getLikedTracks()
        }
    }

    public func refresh() {
        loadData()
    }
}
