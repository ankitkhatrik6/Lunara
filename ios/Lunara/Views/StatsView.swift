import SwiftUI

public struct StatsView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("Listening Stats")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.spotifyTextPrimary)

                        Text("Your personal listening statistics.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.spotifyTextMuted)
                    }

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "Total Tracks Played", value: "\(StorageService.shared.getPlayHistory().count)", icon: "music.note")
                        StatCard(title: "Liked Songs", value: "\(StorageService.shared.getLikedTracks().count)", icon: "heart.fill")
                        StatCard(title: "Playlists", value: "\(StorageService.shared.getPlaylists().count)", icon: "music.playlist")
                        StatCard(title: "Downloads", value: "\(StorageService.shared.getDownloads().count)", icon: "arrow.down.circle")
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Artists")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.spotifyTextPrimary)

                        ForEach(Array(Set(StorageService.shared.getPlayHistory().map { $0.track.artistName })).prefix(10), id: \.self) { artist in
                            HStack {
                                Text(artist)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.spotifyTextPrimary)
                                Spacer()
                                Image(systemName: "music.note")
                                    .foregroundColor(.spotifyTextMuted)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 16)
                            .background(Color.spotifyCardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 40)
                }
            }
            .background(Color.spotifyBackground.ignoresSafeArea())
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

public struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    public init(title: String, value: String, icon: String) {
        self.title = title
        self.value = value
        self.icon = icon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.spotifyGreen)
                Spacer()
            }
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.spotifyTextPrimary)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.spotifyTextMuted)
        }
        .padding(16)
        .background(Color.spotifyCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}