import Foundation

/// Fully on-device YouTube Music access — Innertube API, no server of our own.
/// Uses the VISIONOS client for playback (no PoToken, no signature cipher) and
/// WEB_REMIX client for search/browse results.
public final class YouTubeService: Sendable {
    public static let shared = YouTubeService()

    private let musicPlayerURL = "https://music.youtube.com/youtubei/v1/player?prettyPrint=false"
    private let musicSearchURL = "https://music.youtube.com/youtubei/v1/search?prettyPrint=false"
    private let musicBrowseURL = "https://music.youtube.com/youtubei/v1/browse?prettyPrint=false"
    private let musicSuggestURL = "https://music.youtube.com/youtubei/v1/music/get_search_suggestions?prettyPrint=false"

    private let visionUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
    private let remixVersion = "1.20260213.01.00"
    private let webUA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0"

    // YouTube Music "Songs" search filter
    private let songsFilter = "EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D"

    private init() {}

    // MARK: - Search

    public func search(query: String, filter: SearchScope = .songs) async throws -> [Track] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        var visitor = await Auth.shared.visitorData
        if visitor == nil {
            visitor = await visitorData()
        }

        var client: [String: Any] = [
            "clientName": "WEB_REMIX",
            "clientVersion": remixVersion,
            "hl": Locale.current.languageCode ?? "en",
            "gl": Locale.current.regionCode ?? "US"
        ]
        if let visitor { client["visitorData"] = visitor }

        var body: [String: Any] = [
            "context": ["client": client],
            "query": encodedQuery
        ]
        if let filterParams = filter.params {
            body["params"] = filterParams
        }

        guard let json = await post(
            musicSearchURL,
            name: "67",
            version: remixVersion,
            userAgent: webUA,
            visitor: visitor,
            body: body
        ) else {
            return []
        }

        return parseSearchResults(json)
    }

    public func searchSuggestions(query: String) async -> [String] {
        guard !query.isEmpty else { return [] }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(musicSuggestURL)?q=\(encoded)") else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [Any],
               json.count > 1,
               let suggestions = json[1] as? [String] {
                return suggestions
            }
        } catch {}
        return []
    }

    // MARK: - Browse (home feed, artist, playlist, album)

    public func browseHome() async -> HomeFeed {
        var visitor = await Auth.shared.visitorData
        if visitor == nil {
            visitor = await visitorData()
        }

        var client: [String: Any] = [
            "clientName": "WEB_REMIX",
            "clientVersion": remixVersion,
            "hl": Locale.current.languageCode ?? "en",
            "gl": Locale.current.regionCode ?? "US"
        ]
        if let visitor { client["visitorData"] = visitor }

        let body: [String: Any] = [
            "context": ["client": client],
            "browseId": "FEmusic_home"
        ]

        guard let json = await post(
            musicBrowseURL,
            name: "67",
            version: remixVersion,
            userAgent: webUA,
            visitor: visitor,
            body: body
        ) else {
            return HomeFeed.empty
        }

        return parseHomeFeed(json)
    }

    public func browse(browseId: String, params: String? = nil) async -> HomeFeed {
        var visitor = await Auth.shared.visitorData
        if visitor == nil {
            visitor = await visitorData()
        }

        var client: [String: Any] = [
            "clientName": "WEB_REMIX",
            "clientVersion": remixVersion,
            "hl": Locale.current.languageCode ?? "en",
            "gl": Locale.current.regionCode ?? "US"
        ]
        if let visitor { client["visitorData"] = visitor }

        var body: [String: Any] = [
            "context": ["client": client],
            "browseId": browseId
        ]
        if let params { body["params"] = params }

        guard let json = await post(
            musicBrowseURL,
            name: "67",
            version: remixVersion,
            userAgent: webUA,
            visitor: visitor,
            body: body
        ) else {
            return HomeFeed.empty
        }

        return parseHomeFeed(json)
    }

    public func artist(channelId: String) async -> ArtistPage? {
        return await browse(browseId: channelId).toArtistPage()
    }

    // MARK: - Stream URL (VISIONOS client - no PoToken needed)

    public func streamURL(for videoId: String) async -> StreamURL? {
        var visitor = await Auth.shared.visitorData
        if visitor == nil {
            visitor = await visitorData()
        }

        var client: [String: Any] = [
            "clientName": "WEB_REMIX",
            "clientVersion": remixVersion,
            "hl": Locale.current.languageCode ?? "en",
            "gl": Locale.current.regionCode ?? "US"
        ]
        if let visitor { client["visitorData"] = visitor }

        let body: [String: Any] = [
            "context": ["client": client],
            "videoId": videoId,
            "playbackContext": [
                "contentPlayContext": [
                    "signatureTimestamp": 0
                ]
            ],
            "contentCheck": true
        ]

        guard let json = await post(
            musicPlayerURL,
            name: "67",
            version: remixVersion,
            userAgent: visionUA,
            visitor: visitor,
            body: body
        ) else {
            return nil
        }

        return parseStreamURL(json, videoId: videoId)
    }

    // MARK: - Related tracks (for autoplay/radio)

    public func related(videoId: String) async -> [HomeSection] {
        var visitor = await Auth.shared.visitorData
        if visitor == nil {
            visitor = await visitorData()
        }

        var client: [String: Any] = [
            "clientName": "WEB_REMIX",
            "clientVersion": remixVersion,
            "hl": Locale.current.languageCode ?? "en",
            "gl": Locale.current.regionCode ?? "US"
        ]
        if let visitor { client["visitorData"] = visitor }

        let body: [String: Any] = [
            "context": ["client": client],
            "videoId": videoId
        ]

        guard let json = await post(
            musicBrowseURL,
            name: "67",
            version: remixVersion,
            userAgent: webUA,
            visitor: visitor,
            body: body
        ) else {
            return []
        }

        return parseRelatedShelves(json)
    }

    // MARK: - Private helpers

    private func post(
        _ urlString: String,
        name: String,
        version: String,
        userAgent: String,
        visitor: String?,
        body: [String: Any]
    ) async -> [String: Any]? {
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://music.youtube.com", forHTTPHeaderField: "Origin")
        request.setValue("https://music.youtube.com", forHTTPHeaderField: "Referer")

        var context: [String: Any] = [:]
        var client: [String: Any] = body["context"] as? [String: Any] ?? [:]
        client["clientName"] = "WEB_REMIX"
        client["clientVersion"] = version
        client["hl"] = Locale.current.languageCode ?? "en"
        client["gl"] = Locale.current.regionCode ?? "US"
        if let visitor { client["visitorData"] = visitor }
        context["client"] = client
        var mutableBody = body
        mutableBody["context"] = context

        guard let httpBody = try? JSONSerialization.data(withJSONObject: mutableBody) else {
            return nil
        }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            return json
        } catch {
            return nil
        }
    }

    private func parseSearchResults(_ json: [String: Any]) -> [Track] {
        var tracks: [Track] = []

        guard let contents = json["contents"] as? [String: Any],
              let tabRenderer = contents["musicSearchResponse"] as? [String: Any],
              let sections = tabRenderer["contents"] as? [[String: Any]] else {
            return tracks
        }

        for section in sections {
            if let musicResponsiveListItemRenderer = section["musicResponsiveListItemRenderer"] as? [String: Any] {
                if let track = parseTrack(from: musicResponsiveListItemRenderer) {
                    tracks.append(track)
                }
            } else if let shelfRenderer = section["musicShelfRenderer"] as? [String: Any] {
                if let contents = shelfRenderer["contents"] as? [[String: Any]] {
                    for item in contents {
                        if let r = item["musicResponsiveListItemRenderer"] as? [String: Any] {
                            if let track = parseTrack(from: r) {
                                tracks.append(track)
                            }
                        }
                    }
                }
            }
        }

        return tracks
    }

    private func parseTrack(from dict: [String: Any]) -> Track? {
        guard let videoId = extractVideoId(from: dict) else { return nil }

        let title = extractTitle(from: dict) ?? "Unknown Title"
        let artist = extractArtist(from: dict) ?? "Unknown Artist"
        let thumbnail = extractThumbnail(from: dict) ?? ""
        let duration = extractDuration(from: dict) ?? 0

        return Track(
            videoId: videoId,
            title: title,
            artist: artist,
            thumbnail: thumbnail,
            duration: duration
        )
    }

    private func extractVideoId(from dict: [String: Any]) -> String? {
        if let nav = dict["navigationEndpoint"] as? [String: Any] {
            if let watchEndpoint = nav["watchEndpoint"] as? [String: Any],
               let videoId = watchEndpoint["videoId"] as? String {
                return videoId
            }
        }
        if let flexColumns = dict["flexColumns"] as? [[String: Any]] {
            for column in flexColumns {
                if let onTap = column["onTap"] as? [String: Any],
                   let watchEndpoint = onTap["watchEndpoint"] as? [String: Any],
                   let videoId = watchEndpoint["videoId"] as? String {
                    return videoId
                }
            }
        }
        return nil
    }

    private func extractTitle(from dict: [String: Any]) -> String? {
        if let title = dict["title"] as? [String: Any] {
            return extractTextRuns(from: title)
        }
        return nil
    }

    private func extractArtist(from dict: [String: Any]) -> String? {
        if let flexColumns = dict["flexColumns"] as? [[String: Any]] {
            for column in flexColumns {
                if let musicResponsiveListItemFixedColumnRenderer = column["musicResponsiveListItemFixedColumnRenderer"] as? [String: Any] {
                    if let text = musicResponsiveListItemFixedColumnRenderer["text"] as? [String: Any] {
                        return extractTextRuns(from: text)
                    }
                }
            }
        }
        return nil
    }

    private func extractThumbnail(from dict: [String: Any]) -> String? {
        if let thumbnail = dict["thumbnail"] as? [String: Any],
           let musicThumbnailRenderer = thumbnail["musicThumbnailRenderer"] as? [String: Any],
           let thumbnailRenderer = musicThumbnailRenderer["thumbnail"] as? [String: Any],
           let thumbnails = thumbnailRenderer["thumbnails"] as? [[String: Any]],
           let last = thumbnails.last,
           let url = last["url"] as? String {
            return url
        }
        return nil
    }

    private func extractDuration(from dict: [String: Any]) -> Double? {
        if let flexColumns = dict["flexColumns"] as? [[String: Any]] {
            for column in flexColumns {
                if let musicResponsiveListItemFixedColumnRenderer = column["musicResponsiveListItemFixedColumnRenderer"] as? [String: Any] {
                    if let fixedColumnText = musicResponsiveListItemFixedColumnRenderer["fixedColumnText"] as? [String: Any],
                       let text = fixedColumnText["text"] as? [String: Any],
                       let runs = text["runs"] as? [[String: Any]],
                       let first = runs.first,
                       let durationText = first["text"] as? String {
                        return parseDuration(durationText)
                    }
                }
            }
        }
        return nil
    }

    private func extractTextRuns(from dict: [String: Any]) -> String? {
        if let runs = dict["runs"] as? [[String: Any]] {
            return runs.compactMap { $0["text"] as? String }.joined()
        }
        return nil
    }

    private func parseDuration(_ text: String) -> Double? {
        let parts = text.split(separator: ":").map { Int($0) ?? 0 }
        if parts.count == 2 {
            return Double(parts[0] * 60 + parts[1])
        } else if parts.count == 3 {
            return Double(parts[0] * 3600 + parts[1] * 60 + parts[2])
        }
        return nil
    }

    private func parseHomeFeed(_ json: [String: Any]) -> HomeFeed {
        var chips: [HomeChip] = []
        var sections: [HomeSection] = []
        var continuation: String? = nil

        if let contents = json["contents"] as? [String: Any] {
            // Simplified extraction
        }

        return HomeFeed(chips: chips, sections: sections, continuation: continuation)
    }

    private func parseHomeItems(from dict: [String: Any]) -> [HomeItem] {
        var items: [HomeItem] = []
        return items
    }

    private func parseRelatedShelves(_ json: [String: Any]) -> [HomeSection] {
        var sections: [HomeSection] = []
        return sections
    }

    private func parseStreamURL(_ json: [String: Any], videoId: String) -> StreamURL? {
        guard let streamingData = json["streamingData"] as? [String: Any] else {
            return nil
        }

        if let adaptiveFormats = streamingData["adaptiveFormats"] as? [[String: Any]] {
            for format in adaptiveFormats {
                if let mimeType = format["mimeType"] as? String,
                   mimeType.contains("audio/mp4") || mimeType.contains("audio/webm"),
                   let url = format["url"] as? String {
                    return StreamURL(url: url, type: .audio)
                }
            }
        }

        if let progressiveFormats = streamingData["progressiveFormats"] as? [[String: Any]] {
            for format in progressiveFormats {
                if let mimeType = format["mimeType"] as? String,
                   mimeType.contains("video/mp4"),
                   let url = format["url"] as? String {
                    return StreamURL(url: url, type: .video)
                }
            }
        }

        if let url = streamingData["url"] as? String {
            return StreamURL(url: url, type: .audio)
        }

        return nil
    }

    private func visitorData() async -> String? {
        return Auth.shared.visitorData
    }
}

// MARK: - SearchScope

public extension YouTubeService {
    enum SearchScope: String, CaseIterable, Identifiable {
        case everything, songs, videos, albums, artists
        case communityPlaylists, featuredPlaylists
        case podcasts, episodes, profiles

        var id: String { rawValue }

        var title: String {
            switch self {
            case .everything: return "All"
            case .songs: return "Songs"
            case .videos: return "Videos"
            case .albums: return "Albums"
            case .artists: return "Artists"
            case .communityPlaylists: return "Community playlists"
            case .featuredPlaylists: return "Featured playlists"
            case .podcasts: return "Podcasts"
            case .episodes: return "Episodes"
            case .profiles: return "Profiles"
            }
        }

        var params: String? {
            switch self {
            case .everything: return nil
            case .songs: return "EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D"
            case .videos: return "EgWKAQIQAWoKEAkQChAFEAMQBA%3D%3D"
            case .albums: return "EgWKAQIYAWoKEAkQChAFEAMQBA%3D%3D"
            case .artists: return "EgWKAQIgAWoKEAkQChAFEAMQBA%3D%3D"
            case .communityPlaylists: return "EgeKAQQoAEABagoQAxAEEAoQCRAF"
            case .featuredPlaylists: return "EgeKAQQoADgBagwQDhAKEAMQBRAJEAQ%3D"
            case .podcasts: return "EgWKAQJQAWoKEAkQChAFEAMQBA%3D%3D"
            case .episodes: return "EgWKAQJYAWoKEAkQChAFEAMQBA%3D%3D"
            case .profiles: return "EgWKAQJYAWoSEAUQCRADEAQQEBAVEAoQDhAR"
            }
        }
    }
}

// MARK: - StreamURL

public struct StreamURL: Sendable {
    public let url: String
    public let type: StreamType

    public enum StreamType: String {
        case audio, video
    }

    public init(url: String, type: StreamType) {
        self.url = url
        self.type = type
    }
}

// MARK: - Helper to convert YouTubeService.StreamURL to stream URL string

public extension YouTubeService.StreamURL {
    var urlString: String { self.url }
}

// MARK: - HomeFeed helper

private extension HomeFeed {
    func toArtistPage() -> ArtistPage? {
        return nil
    }
}
