import SwiftUI

public struct QueueView: View {
    @State var playerVM: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    public init(playerVM: PlayerViewModel) {
        self.playerVM = playerVM
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.spotifyBackground.ignoresSafeArea()

                if playerVM.queue.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(.spotifyTextMuted)
                        Text("Queue is empty")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.spotifyTextPrimary)
                        Text("Add songs to see them here")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.spotifyTextMuted)
                    }
                } else {
                    List {
                        ForEach(Array(playerVM.queue.enumerated()), id: \.offset) { index, track in
                            QueueRowView(
                                track: track,
                                isPlaying: playerVM.currentTrack?.id == track.id,
                                index: index + 1,
                                onTap: {
                                    playerVM.playQueueItem(at: index)
                                },
                                onRemove: {
                                    playerVM.removeFromQueue(at: index)
                                }
                            )
                            .listRowBackground(Color.spotifyCardSurface)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                playerVM.removeFromQueue(at: index)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.spotifyGreen)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear") {
                        playerVM.clearQueue()
                        dismiss()
                    }
                    .foregroundColor(.red)
                    .disabled(playerVM.queue.isEmpty)
                }
            }
        }
    }
}

public struct QueueRowView: View {
    let track: Track
    let isPlaying: Bool
    let index: Int
    let onTap: () -> Void
    let onRemove: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isPlaying ? .spotifyGreen : .spotifyTextMuted)
                .frame(width: 20)

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
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isPlaying ? .spotifyTextPrimary : .spotifyTextPrimary)
                    .lineLimit(1)
                Text(track.artistName)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.spotifyTextMuted)
                    .lineLimit(1)
            }

            Spacer()

            if isPlaying {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.spotifyGreen)
            }

            Button {
                onRemove()
            } label: {
                Image(systemName: "minus.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.spotifyTextMuted)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .padding(.vertical, 4)
    }
}