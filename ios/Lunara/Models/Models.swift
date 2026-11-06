import Foundation

// MARK: - Track (matches Blazify iOS Models.swift)

public struct Track: Identifiable, Codable, Hashable, Sendable {
    public let videoId: String
    public let title: String
    public let artist: String
    public let thumbnail: String
    public let duration: Double
    public let artistId: String?
    public var explicit: Bool?
    public var video: Bool?
    public var videoType: String?
    public var setVideoId: String?
    public var isLiked: Bool = false

    public var isExplicit: Bool { explicit ?? false }
    public var isVideo: Bool { video ?? false }
    public var isOfficialVideo: Bool { videoType == "MUSIC_VIDEO_TYPE_OMV" }

    public var id: String { videoId }

    // Backward-compatible accessors
    public var artistName: String { artist }
    public var artworkUrl: String { thumbnail }

    public var thumbnailURL: URL? {
        guard !thumbnail.isEmpty else { return nil }
        return URL(string: thumbnail)
    }

    public init(
        videoId: String,
        title: String,
        artist: String,
        thumbnail: String = "",
        duration: Double = 0,
        artistId: String? = nil,
        explicit: Bool? = nil,
        video: Bool? = nil,
        videoType: String? = nil,
        setVideoId: String? = nil,
        isLiked: Bool = false
    ) {
        self.videoId = videoId
        self.title = title
        self.artist = artist
        self.thumbnail = thumbnail
        self.duration = duration
        self.artistId = artistId
        self.explicit = explicit
        self.video = video
        self.videoType = videoType
        self.setVideoId = setVideoId
        self.isLiked = isLiked
    }

    public var formattedDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private enum CodingKeys: String, CodingKey {
        case videoId, title, artist, thumbnail, duration, artistId, explicit, video, videoType, setVideoId, isLiked
    }
}

// MARK: - HomeItem

public struct HomeItem: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let thumbnail: String
    public let videoId: String?
    public let browseId: String?
    public let isCircular: Bool
    public var duration: Double = 0

    public var thumbnailURL: URL? { URL(string: thumbnail) }

    public var asTrack: Track {
        Track(
            videoId: videoId ?? "",
            title: title,
            artist: subtitle,
            thumbnail: thumbnail,
            duration: duration
        )
    }

    public init(
        title: String,
        subtitle: String,
        thumbnail: String = "",
        videoId: String? = nil,
        browseId: String? = nil,
        isCircular: Bool = false,
        duration: Double = 0
    ) {
        self.title = title
        self.subtitle = subtitle
        self.thumbnail = thumbnail
        self.videoId = videoId
        self.browseId = browseId
        self.isCircular = isCircular
        self.duration = duration
    }
}

// MARK: - HomeSection

public struct HomeSection: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let title: String
    public let items: [HomeItem]
    public let isSongs: Bool
    public var browseId: String?
    public var params: String?

    public init(
        title: String,
        items: [HomeItem],
        isSongs: Bool = false,
        browseId: String? = nil,
        params: String? = nil
    ) {
        self.title = title
        self.items = items
        self.isSongs = isSongs
        self.browseId = browseId
        self.params = params
    }
}

// MARK: - HomeChip

public struct HomeChip: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let title: String
    public let params: String?

    public init(title: String, params: String? = nil) {
        self.title = title
        self.params = params
    }
}

// MARK: - MoodItem

public struct MoodItem: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let title: String
    public let colorARGB: UInt
    public let browseId: String?
    public let params: String?
    public var isGenre: Bool = false

    public init(
        title: String,
        colorARGB: UInt,
        browseId: String? = nil,
        params: String? = nil,
        isGenre: Bool = false
    ) {
        self.title = title
        self.colorARGB = colorARGB
        self.browseId = browseId
        self.params = params
        self.isGenre = isGenre
    }
}

// MARK: - UserPlaylist

public struct UserPlaylist: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let thumbnail: String
    public var trackCount: Int
    public var tracks: [Track]

    public var thumbnailURL: URL? { URL(string: thumbnail) }

    public init(
        id: String,
        title: String,
        thumbnail: String = "",
        trackCount: Int = 0,
        tracks: [Track] = []
    ) {
        self.id = id
        self.title = title
        self.thumbnail = thumbnail
        self.trackCount = trackCount > 0 ? trackCount : tracks.count
        self.tracks = tracks
    }
}

// MARK: - ArtistPage

public struct ArtistPage: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let thumbnail: String
    public let subscribers: String
    public var following: Bool = false
    public var channelId: String?
    public var sections: [ArtistSection] = []

    public var thumbnailURL: URL? { URL(string: thumbnail) }

    public init(
        id: String,
        name: String,
        thumbnail: String = "",
        subscribers: String = "",
        following: Bool = false,
        channelId: String? = nil,
        sections: [ArtistSection] = []
    ) {
        self.id = id
        self.name = name
        self.thumbnail = thumbnail
        self.subscribers = subscribers
        self.following = following
        self.channelId = channelId
        self.sections = sections
    }
}

// MARK: - ArtistSection

public struct ArtistSection: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let title: String
    public let songs: [Track]
    public let cards: [HomeItem]

    public init(title: String, songs: [Track] = [], cards: [HomeItem] = []) {
        self.title = title
        self.songs = songs
        self.cards = cards
    }
}

// MARK: - HomeFeed

public struct HomeFeed: Identifiable, Sendable {
    public let id = UUID()
    public var chips: [HomeChip]
    public var sections: [HomeSection]
    public var continuation: String?

    public static let empty = HomeFeed(chips: [], sections: [], continuation: nil)

    public init(chips: [HomeChip] = [], sections: [HomeSection] = [], continuation: String? = nil) {
        self.chips = chips
        self.sections = sections
        self.continuation = continuation
    }
}

// MARK: - LyricLine

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

// MARK: - PlayHistoryItem

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

// MARK: - SpeedDialItem

public struct SpeedDialItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let type: String
    public let artworkUrl: String?
    public let trackId: String?
    public let playlistId: String?

    public init(
        title: String,
        type: String,
        artworkUrl: String? = nil,
        trackId: String? = nil,
        playlistId: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.type = type
        self.artworkUrl = artworkUrl
        self.trackId = trackId
        self.playlistId = playlistId
    }
}

// MARK: - BlockedArtist

public struct BlockedArtist: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - DownloadItem

public struct DownloadItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let track: Track
    public let downloadedAt: Date
    public var isDownloaded: Bool

    public init(
        track: Track,
        downloadedAt: Date = Date(),
        isDownloaded: Bool = true
    ) {
        self.id = UUID()
        self.track = track
        self.downloadedAt = downloadedAt
        self.isDownloaded = isDownloaded
    }
}

// MARK: - Playlist

public struct Playlist: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let authorName: String
    public let artworkUrl: String?
    public var trackCount: Int
    public var tracks: [Track]

    public var thumbnailURL: URL? { URL(string: artworkUrl ?? "") }

    public init(
        id: String,
        title: String,
        authorName: String = "Lunara",
        artworkUrl: String? = nil,
        trackCount: Int = 0,
        tracks: [Track] = []
    ) {
        self.id = id
        self.title = title
        self.authorName = authorName
        self.artworkUrl = artworkUrl
        self.trackCount = trackCount > 0 ? trackCount : tracks.count
        self.tracks = tracks
    }
}

// MARK: - Album

public struct Album: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let artistName: String
    public let artworkUrl: String?
    public let year: String?
    public var trackCount: Int?

    public init(
        id: String,
        title: String,
        artistName: String,
        artworkUrl: String? = nil,
        year: String? = nil,
        trackCount: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artworkUrl = artworkUrl
        self.year = year
        self.trackCount = trackCount
    }
}

// MARK: - Artist

public struct Artist: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let avatarUrl: String?
    public let subscribers: String?

    public init(
        id: String,
        name: String,
        avatarUrl: String? = nil,
        subscribers: String? = nil
    ) {
        self.id = id
        self.name = name
        self.avatarUrl = avatarUrl
        self.subscribers = subscribers
    }
}
