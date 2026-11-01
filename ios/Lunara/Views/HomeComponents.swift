import SwiftUI

public struct QuickAccessCard: View {
    public let track: Track
    public let onPlay: () -> Void

    public init(track: Track, onPlay: @escaping () -> Void) {
        self.track = track
        self.onPlay = onPlay
    }

    public var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: track.artworkUrl ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.spotifyCardSurface)
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(.spotifyTextMuted)
                            )
                    }
                }
                .frame(width: 52, height: 52)
                .clipped()

                Text(track.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.spotifyTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 8)
            }
            .frame(height: 52)
            .background(Color.spotifyElevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

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
                .foregroundColor(.spotifyTextPrimary)
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
                                                    .foregroundColor(.spotifyTextMuted)
                                            )
                                    }
                                }
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                Text(track.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.spotifyTextPrimary)
                                    .lineLimit(1)

                                Text(track.artistName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.spotifyTextMuted)
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
