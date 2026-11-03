import SwiftUI

// MARK: - Section Shelf View (matches Android shelf design)

public struct SectionShelfView: View {
    public let title: String
    public let tracks: [Track]
    public let onSelectTrack: (Track) -> Void

    public init(title: String, tracks: [Track], onSelectTrack: @escaping (Track) -> Void) {
        self.title = title
        self.tracks = tracks
        self.onSelectTrack = onSelectTrack
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.spotifyTextPrimary)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(tracks) { track in
                        Button {
                            onSelectTrack(track)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                AsyncImage(url: URL(string: track.artworkUrl ?? "")) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        Rectangle()
                                            .fill(Color.spotifyCardSurface)
                                            .overlay(
                                                Image(systemName: "music.quarternote.3")
                                                    .foregroundColor(Color.spotifyTextMuted)
                                            )
                                    }
                                }
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                Text(track.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.spotifyTextPrimary)
                                    .lineLimit(1)

                                Text(track.artistName)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.spotifyTextMuted)
                                    .lineLimit(1)
                            }
                            .frame(width: 140)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
