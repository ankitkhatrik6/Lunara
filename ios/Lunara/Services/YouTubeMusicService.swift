import Foundation

/// YouTubeMusicService — delegates to YouTubeService (real Innertube API).
/// Provides the same interface the ViewModels expect, but backed by actual
/// YouTube Music data instead of hardcoded sample tracks.
public final class YouTubeMusicService: Sendable {
    public static let shared = YouTubeMusicService()

    private init() {}

    // MARK: - Stream URL

    public func getStreamUrl(for trackId: String) -> String? {
        // Synchronous wrapper: use asyncGetStreamUrl instead
        return nil
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

    // MARK: - Lyrics

    public func fetchLyrics(for videoId: String, title: String, artist: String) async throws -> [LyricLine] {
        // Try to get lyrics from YouTube
        return await withCheckedThrowingContinuation { continuation in
            Task {
                let result = await fetchLyricsFromYouTube(videoId: videoId, title: title, artist: artist)
                continuation.resume(returning: result)
            }
        }
    }

    private func fetchLyricsFromYouTube(videoId: String, title: String, artist: String) async -> [LyricLine] {
        // Try YouTube's timedtext API for captions/lyrics
        let captionURL = "https://www.youtube.com/api/timedtext?v=\(videoId)&type=track&lang=en&kind=asr"
        guard let url = URL(string: captionURL) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let xml = String(data: data, encoding: .utf8) {
                return parseTimedTextXML(xml)
            }
        } catch {}

        // Fallback: try to get lyrics from YouTube Music page
        return []
    }

    private func parseTimedTextXML(_ xml: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let pattern = #"<text start="([\d.]+)" dur="([\d.]+)">([^<]*)</text>"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let nsString = xml as NSString
        let matches = regex?.matches(in: xml, range: NSRange(location: 0, length: nsString.length)) ?? []

        for match in matches {
            let start = nsString.substring(with: match.range(at: 1))
            let text = nsString.substring(with: match.range(at: 3))
            let startTime = Double(start) ?? 0
            let cleanText = text.replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&#39;", with: "'")
                .replacingOccurrences(of: "&quot;", with: "\"")
            if !cleanText.isEmpty {
                lines.append(LyricLine(timestamp: startTime, text: cleanText))
            }
        }
        return lines
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

// MARK: - Auth (stub for sign-in)

public extension YouTubeMusicService {
    func accountInfo() async -> (name: String, email: String, photo: String)? {
        // Stub - no real auth integration yet
        return nil
    }
}
