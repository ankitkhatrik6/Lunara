import SwiftUI

public struct DownloadsView: View {
    @State private var downloads: [DownloadItem] = []

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if downloads.isEmpty {
                    ContentUnavailableView(
                        "No Downloads",
                        systemImage: "arrow.down.circle",
                        description: Text("Downloaded tracks will appear here.")
                    )
                } else {
                    List {
                        ForEach(downloads) { item in
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

                                    Text(item.downloadedAt.formatted(.dateTime.day().month()))
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(.spotifyTextMuted)
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.spotifyGreen)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                StorageService.shared.removeDownload(trackId: downloads[index].track.id)
                            }
                            downloads.remove(atOffsets: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                downloads = StorageService.shared.getDownloads()
            }
        }
    }
}