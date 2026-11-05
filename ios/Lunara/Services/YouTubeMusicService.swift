import Foundation

/// YouTubeMusicService — delegates to YouTubeService (real Innertube API).
/// Provides the same interface the ViewModels expect, but backed by actual
/// YouTube Music data instead of hardcoded sample tracks.
public final class YouTubeMusicService: Sendable {
    public static let shared = YouTubeMusicService()

    private init() {}

    // MARK: - Stream URL

    public func getStreamUrl(for trackId: String) -> String? {
        // Synchronous wrapper: caller awaits async version
        return nil  // Use asyncGetStreamUrl instead
    }

    public func asyncGetStreamUrl(for videoId: String) async -> YouTubeService.StreamURL? {
        return await YouTubeService.shared.streamURL(for: videoId)
    }

    // MARK: - Search

    public func search(query: String) async throws -> [Track] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        return await YouTubeService.shared.search(query: query, filter: .songs)
    }

    public func fetchSuggestions(query: String) async -> [String] {
        return await YouTubeService.shared.searchSuggestions(query: query)
    }

    // MARK: - Home

    public func fetchHome() async -> HomeFeed {
        return await YouTubeService.shared.browseHome()
    }

    public func browse(browseId: String, params: String? = nil) async -> HomeFeed {
        return await YouTubeService.shared.browse(browseId: browseId, params: params)
    }

    public func artist(channelId: String) async -> ArtistPage? {
        return await YouTubeService.shared.artist(channelId: channelId)
    }

    // MARK: - Related (autoplay radio)

    public func related(videoId: String) async -> [HomeSection] {
        return await YouTubeService.shared.related(videoId: videoId)
    }

    // MARK: - Deprecated sampleTracks (kept for backward compat — empty now)

    public var sampleTracks: [Track] {
        []  // No more hardcoded demo tracks
    }
}

// MARK: - Helper to convert YouTubeService.StreamURL to stream URL string

public extension YouTubeService.StreamURL {
    var urlString: String { self.url }
}
