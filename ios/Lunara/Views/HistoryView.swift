import SwiftUI

public struct HistoryView: View {
    @State private var history: [PlayHistoryItem] = []
    @State private var isLoading: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    ContentUnavailableView(
                        "No Play History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Tracks you play will appear here.")
                    )
                } else {
                    List {
                        ForEach(history) { item in
                            HStack(spacing: 12) {
                                if let url = URL(string: item.track.artworkUrl ?? "") {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Rectangle().fill(Color.spotifyCardSurface)
                                        }
                                    }
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                } else {
                                    Rectangle()
                                        .fill(Color.spotifyCardSurface)
                                        .frame(width: 48, height: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.track.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.spotifyTextPrimary)
                                        .lineLimit(1)

                                    Text(item.track.artistName)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.spotifyTextMuted)
                                        .lineLimit(1)

                                    Text(item.playedAt.formatted(.dateTime.hour().minute()))
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(.spotifyTextMuted)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Play from history
                            }
                        }
                        .onDelete { indexSet in
                            // Delete from history
                        }
                    }
                }
            }
            .navigationTitle("Play History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear") {
                        history.removeAll()
                        StorageService.shared.clearPlayHistory()
                    }
                    .foregroundColor(.red)
                    .disabled(history.isEmpty)
                }
            }
            .onAppear {
                history = StorageService.shared.getPlayHistory()
            }
        }
    }
}