import SwiftUI

public struct MiniPlayerView: View {
    @Bindable public var playerVM: PlayerViewModel

    public var body: some View {
        if let track = playerVM.currentTrack {
            VStack(spacing: 0) {
                // Main MiniPlayer Body
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: track.artworkUrl ?? "")) { phase in
                        if let img = phase.image {
                            img
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
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.spotifyTextPrimary)
                            .lineLimit(1)

                        Text(track.artistName)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.spotifyTextMuted)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Like button
                    Button {
                        playerVM.toggleLike()
                    } label: {
                        Image(systemName: (playerVM.currentTrack?.isLiked ?? false) ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor((playerVM.currentTrack?.isLiked ?? false) ? .spotifyGreen : .spotifyTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)

                    // Play / Pause toggle
                    Button {
                        playerVM.togglePlayPause()
                    } label: {
                        Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.spotifyTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.spotifyCardSurface)

                // Thin progress track at bottom
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 2)

                        Rectangle()
                            .fill(Color.spotifyGreen)
                            .frame(width: geo.size.width * playerVM.progress, height: 2)
                    }
                }
                .frame(height: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                playerVM.isFullScreenPresented = true
            }
        }
    }
}
