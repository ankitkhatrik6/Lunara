import SwiftUI

public struct SpeedDialView: View {
    @State private var items: [SpeedDialItem] = []

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Speed Dial Items",
                        systemImage: "phone.fill",
                        description: Text("Pin your favorite tracks and playlists here.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(items) { item in
                                SpeedDialCard(item: item)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .navigationTitle("Speed Dial")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                items = StorageService.shared.getSpeedDial()
            }
        }
    }
}

public struct SpeedDialCard: View {
    let item: SpeedDialItem

    public init(item: SpeedDialItem) {
        self.item = item
    }

    public var body: some View {
        VStack(spacing: 8) {
            if let url = URL(string: item.artworkUrl ?? "") {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Color.spotifyCardSurface)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                Rectangle()
                    .fill(Color.spotifyCardSurface)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Text(item.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.spotifyTextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}