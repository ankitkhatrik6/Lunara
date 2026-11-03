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
        let allSamples = YouTubeMusicService.shared.sampleTracks
        self.quickAccessTracks = Array(allSamples.prefix(6))
        self.recentlyPlayed = allSamples
        self.trendingHits = allSamples.reversed()
        self.likedTracks = allSamples.filter { $0.isLiked }

        self.recommendedAlbums = [
            Album(id: "meteora", title: "Meteora", artistName: "Linkin Park", artworkUrl: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&q=80", year: "2003"),
            Album(id: "opera", title: "A Night at the Opera", artistName: "Queen", artworkUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80", year: "1975"),
            Album(id: "native", title: "Native", artistName: "OneRepublic", artworkUrl: "https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=500&q=80", year: "2013"),
            Album(id: "hurry_up", title: "Hurry Up, We're Dreaming", artistName: "M83", artworkUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80", year: "2011")
        ]
    }
}
