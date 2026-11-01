import Foundation

public struct Track: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let artistName: String
    public let albumName: String?
    public let artworkUrl: String?
    public let durationSeconds: Double
    public let streamUrl: String?
    public var isLiked: Bool
    
    public init(
        id: String,
        title: String,
        artistName: String,
        albumName: String? = nil,
        artworkUrl: String? = nil,
        durationSeconds: Double = 0,
        streamUrl: String? = nil,
        isLiked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.albumName = albumName
        self.artworkUrl = artworkUrl
        self.durationSeconds = durationSeconds
        self.streamUrl = streamUrl
        self.isLiked = isLiked
    }
    
    public var formattedDuration: String {
        let mins = Int(durationSeconds) / 60
        let secs = Int(durationSeconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
