import Foundation

public struct Album: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let artistName: String
    public let artworkUrl: String?
    public let year: String?
    public let trackCount: Int?

    public init(id: String, title: String, artistName: String, artworkUrl: String? = nil, year: String? = nil, trackCount: Int? = nil) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artworkUrl = artworkUrl
        self.year = year
        self.trackCount = trackCount
    }
}

public struct Artist: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let avatarUrl: String?
    public let subscribers: String?

    public init(id: String, name: String, avatarUrl: String? = nil, subscribers: String? = nil) {
        self.id = id
        self.name = name
        self.avatarUrl = avatarUrl
        self.subscribers = subscribers
    }
}

public struct Playlist: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let authorName: String
    public let artworkUrl: String?
    public let trackCount: Int
    public var tracks: [Track]

    public init(id: String, title: String, authorName: String = "Lunara", artworkUrl: String? = nil, trackCount: Int = 0, tracks: [Track] = []) {
        self.id = id
        self.title = title
        self.authorName = authorName
        self.artworkUrl = artworkUrl
        self.trackCount = trackCount > 0 ? trackCount : tracks.count
        self.tracks = tracks
    }
}

public struct LyricLine: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let timestamp: TimeInterval
    public let text: String

    public init(id: UUID = UUID(), timestamp: TimeInterval, text: String) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
    }
}

public struct PlayHistoryItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let track: Track
    public let playedAt: Date

    public init(track: Track, playedAt: Date = Date()) {
        self.id = UUID()
        self.track = track
        self.playedAt = playedAt
    }
}

public struct SpeedDialItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let type: String
    public let artworkUrl: String?
    public let trackId: String?
    public let playlistId: String?

    public init(title: String, type: String, artworkUrl: String? = nil, trackId: String? = nil, playlistId: String? = nil) {
        self.id = UUID()
        self.title = title
        self.type = type
        self.artworkUrl = artworkUrl
        self.trackId = trackId
        self.playlistId = playlistId
    }
}

public struct BlockedArtist: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct DownloadItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let track: Track
    public let downloadedAt: Date
    public var isDownloaded: Bool

    public init(track: Track, downloadedAt: Date = Date(), isDownloaded: Bool = true) {
        self.id = UUID()
        self.track = track
        self.downloadedAt = downloadedAt
        self.isDownloaded = isDownloaded
    }
}