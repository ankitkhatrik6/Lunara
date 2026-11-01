import SwiftUI
import Observation

public struct BrowseCategory: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let color: Color
    public let imageUrl: String
}

@Observable
public final class SearchViewModel {
    public var query: String = "" {
        didSet {
            handleQueryChange()
        }
    }
    public var suggestions: [String] = []
    public var searchResults: [Track] = []
    public var isSearching: Bool = false
    public var recentSearches: [String] = ["Linkin Park", "Adele", "Midnight City", "Coldplay"]
    
    private var searchTask: Task<Void, Never>?
    
    public let browseCategories: [BrowseCategory] = [
        BrowseCategory(id: "pop", title: "Pop", color: Color(red: 141/255, green: 103/255, blue: 171/255), imageUrl: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80"),
        BrowseCategory(id: "hiphop", title: "Hip-Hop", color: Color(red: 220/255, green: 86/255, blue: 40/255), imageUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=300&q=80"),
        BrowseCategory(id: "rock", title: "Rock", color: Color(red: 233/255, green: 20/255, blue: 41/255), imageUrl: "https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=300&q=80"),
        BrowseCategory(id: "indie", title: "Indie", color: Color(red: 96/255, green: 129/255, blue: 8/255), imageUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&q=80"),
        BrowseCategory(id: "chill", title: "Chill", color: Color(red: 45/255, green: 70/255, blue: 185/255), imageUrl: "https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=300&q=80"),
        BrowseCategory(id: "focus", title: "Focus", color: Color(red: 80/255, green: 55/255, blue: 80/255), imageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=300&q=80")
    ]
    
    private func handleQueryChange() {
        searchTask?.cancel()
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            searchResults = []
            suggestions = []
            isSearching = false
            return
        }
        
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            
            self.isSearching = true
            async let fetchedSuggestions = YouTubeMusicService.shared.fetchSuggestions(query: trimmed)
            async let fetchedResults = try? YouTubeMusicService.shared.search(query: trimmed)
            
            self.suggestions = await fetchedSuggestions
            self.searchResults = (await fetchedResults) ?? []
            self.isSearching = false
        }
    }
    
    public func clearQuery() {
        query = ""
        searchResults = []
        suggestions = []
        isSearching = false
    }
}
