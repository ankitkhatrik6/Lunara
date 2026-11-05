import SwiftUI
import Observation

@Observable
@MainActor
public final class SearchViewModel {
    public var query: String = "" {
        didSet {
            handleQueryChange()
        }
    }
    public var searchResults: [Track] = []
    public var isSearching: Bool = false
    public var recentSearches: [String] = ["Linkin Park", "Adele", "Midnight City", "Coldplay"]

    private var searchTask: Task<Void, Never>?

    public init() {}

    private func handleQueryChange() {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            searchResults = []
            isSearching = false
            return
        }

        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            self.isSearching = true

            do {
                let results = try await YouTubeMusicService.shared.search(query: trimmed)
                self.searchResults = results
            } catch {
                self.searchResults = []
            }

            self.isSearching = false
        }
    }

    public func clearQuery() {
        query = ""
        searchResults = []
        isSearching = false
    }
}
