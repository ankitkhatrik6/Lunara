import SwiftUI

public struct HomeView: View {
    var homeVM: HomeViewModel
    var playerVM: PlayerViewModel
    public let onOpenSettings: () -> Void

    public init(homeVM: HomeViewModel, playerVM: PlayerViewModel, onOpenSettings: @escaping () -> Void) {
        self.homeVM = homeVM
        self.playerVM = playerVM
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Top Bar: Logo + Title | Settings
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.spotifyCardSurface)
                                .frame(width: 36, height: 36)
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color.spotifyGreen)
                        }

                        Text("Lunara")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.spotifyTextPrimary)
                    }

                    Spacer()

                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.spotifyTextPrimary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                // MARK: - Greeting + Filter Pills
                VStack(alignment: .leading, spacing: 14) {
                    Text(homeVM.greeting)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color.spotifyTextPrimary)
                        .padding(.horizontal, 16)

                    HStack(spacing: 8) {
                        ForEach(HomeFilterCategory.allCases, id: \.self) { category in
                            Button {
                                homeVM.selectedCategory = category
                            } label: {
                                Text(category.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        homeVM.selectedCategory == category
                                            ? Color.spotifyGreen
                                            : Color.spotifyCardSurface
                                    )
                                    .foregroundColor(
                                        homeVM.selectedCategory == category
                                            ? Color.black
                                            : Color.spotifyTextPrimary
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // MARK: - 2-Column Quick Access Grid
                let columns = [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ]

                LazyVGrid(columns: columns, spacing: 8) {
                    QuickAccessCard(
                        title: "Liked Songs",
                        iconName: "heart.fill",
                        iconColor: Color.white,
                        badgeColor: Color.spotifyLikedPurple,
                        onPlay: {
                            if let first = homeVM.likedTracks.first {
                                playerVM.play(track: first, queue: homeVM.likedTracks)
                            }
                        }
                    )
                    QuickAccessCard(
                        title: "For You",
                        iconName: "music.note",
                        iconColor: Color.black,
                        badgeColor: Color.spotifyGreen,
                        onPlay: {}
                    )
                    QuickAccessCard(
                        title: "Speed Dial",
                        iconName: "radio",
                        iconColor: Color.white,
                        badgeColor: Color.spotifyCardSurface,
                        onPlay: {}
                    )
                    QuickAccessCard(
                        title: "History",
                        iconName: "clock.arrow.circlepath",
                        iconColor: Color.white,
                        badgeColor: Color(red: 30/255, green: 50/255, blue: 100/255),
                        onPlay: {}
                    )
                }
                .padding(.horizontal, 16)

                // MARK: - Shelves
                SectionShelfView(title: "Jump back in", tracks: homeVM.recentlyPlayed) { track in
                    playerVM.play(track: track, queue: homeVM.recentlyPlayed)
                }

                SectionShelfView(title: "Trending Right Now", tracks: homeVM.trendingHits) { track in
                    playerVM.play(track: track, queue: homeVM.trendingHits)
                }

                Spacer(minLength: 80)
            }
        }
        .background(Color.spotifyBackground.ignoresSafeArea())
    }
}

// MARK: - Quick Access Card (matches Android QuickAccessCard)

public struct QuickAccessCard: View {
    let title: String
    let iconName: String
    let iconColor: Color
    let badgeColor: Color
    let onPlay: () -> Void

    public init(title: String, iconName: String, iconColor: Color, badgeColor: Color, onPlay: @escaping () -> Void) {
        self.title = title
        self.iconName = iconName
        self.iconColor = iconColor
        self.badgeColor = badgeColor
        self.onPlay = onPlay
    }

    public var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(badgeColor)
                        .frame(width: 56, height: 56)
                    Image(systemName: iconName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.spotifyTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .background(Color.spotifyElevatedSurface)
        }
        .buttonStyle(.plain)
    }
}
