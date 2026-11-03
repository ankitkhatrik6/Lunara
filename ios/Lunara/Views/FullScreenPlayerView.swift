import SwiftUI

public struct FullScreenPlayerView: View {
    public let playerVM: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isLyricsPresented: Bool = false

    @State private var isDraggingScrubber: Bool = false
    @State private var dragProgress: Double = 0

    public var body: some View {
        ZStack {
            Color.spotifyBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.spotifyTextPrimary)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("PLAYING FROM PLAYLIST")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.spotifyTextMuted)
                            .tracking(1.0)

                        Text(playerVM.currentTrack?.albumName ?? "Lunara Stream")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.spotifyTextPrimary)
                    }

                    Spacer()

                    Button {
                        // Options menu
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.spotifyTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                // Big Album Artwork
                AsyncImage(url: URL(string: playerVM.currentTrack?.artworkUrl ?? "")) { phase in
                    if let img = phase.image {
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.spotifyCardSurface)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 64))
                                    .foregroundColor(.spotifyTextMuted)
                            )
                    }
                }
                .frame(maxWidth: 320, maxHeight: 320)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.4), radius: 24, y: 12)

                Spacer()

                // Track Info & Like Button
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(playerVM.currentTrack?.title ?? "Unknown Title")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.spotifyTextPrimary)
                            .lineLimit(1)

                        Text(playerVM.currentTrack?.artistName ?? "Unknown Artist")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.spotifyTextSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        playerVM.toggleLike()
                    } label: {
                        Image(systemName: (playerVM.currentTrack?.isLiked ?? false) ? "heart.fill" : "heart")
                            .font(.system(size: 24))
                            .foregroundColor((playerVM.currentTrack?.isLiked ?? false) ? .spotifyGreen : .spotifyTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                // Progress scrubber
                VStack(spacing: 8) {
                    HStack {
                        Text(playerVM.formattedCurrentTime)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.spotifyTextMuted)

                        Spacer()

                        Text(playerVM.formattedDuration)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.spotifyTextMuted)
                    }
                    .padding(.horizontal, 24)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 4)
                                .clipShape(Capsule())

                            Rectangle()
                                .fill(Color.spotifyGreen)
                                .frame(width: isDraggingScrubber ? dragProgress : playerVM.progress * geo.size.width, height: 4)
                                .clipShape(Capsule())
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDraggingScrubber = true
                                    dragProgress = max(0, min(1, value.location.x / geo.size.width))
                                }
                                .onEnded { value in
                                    isDraggingScrubber = false
                                    let progress = max(0, min(1, value.location.x / geo.size.width))
                                    playerVM.seek(to: progress * playerVM.duration)
                                }
                        )
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 24)
                }

                // Controls
                HStack(spacing: 30) {
                    Button {
                        playerVM.skipPrevious()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.spotifyTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)

                    Button {
                        playerVM.togglePlayPause()
                    } label: {
                        Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.spotifyTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)

                    Button {
                        playerVM.skipNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.spotifyTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 16)

                // Bottom Bar: Lyrics & AirPlay / Queue
                HStack {
                    Button {
                        playerVM.isLyricsPresented = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "quote.bubble.fill")
                            Text("Lyrics")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.spotifyGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.spotifyCardSurface)
                        .clipShape(Capsule())
                    }

                    Spacer()

                    Button {
                        // Queue Sheet
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 18))
                            .foregroundColor(.spotifyTextPrimary)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $isLyricsPresented) {
            LyricsSheetView(playerVM: playerVM)
        }
        .onChange(of: playerVM.isLyricsPresented) { _, isPresented in
            isLyricsPresented = isPresented
        }
        .onChange(of: isLyricsPresented) { _, isPresented in
            if !isPresented {
                playerVM.isLyricsPresented = false
            }
        }
    }
}

public struct LyricsSheetView: View {
    public let playerVM: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(Array(playerVM.lyrics.enumerated()), id: \.offset) { index, lyric in
                            Text(lyric.text)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(
                                    playerVM.currentLyricIndex == index
                                        ? .white
                                        : .white.opacity(0.35)
                                )
                                .id(index)
                        }
                        Spacer(minLength: 60)
                    }
                    .padding(24)
                }
                .onChange(of: playerVM.currentLyricIndex) { _, newIndex in
                    if let target = newIndex {
                        withAnimation {
                            proxy.scrollTo(target, anchor: .center)
                        }
                    }
                }
            }
            .background(Color.spotifyElevatedSurface.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.spotifyTextPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
