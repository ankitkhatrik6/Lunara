import SwiftUI

public struct HomeView: View {
    @Bindable public var homeVM: HomeViewModel
    @Bindable public var playerVM: PlayerViewModel
    public let onOpenSettings: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    public init(homeVM: HomeViewModel, playerVM: PlayerViewModel, onOpenSettings: @escaping () -> Void) {
        self.homeVM = homeVM
        self.playerVM = playerVM
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header: Logo & Title on Left, Settings on Right
                HStack(alignment: .center) {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.spotifyGreen)

                        Text("Lunara")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.spotifyTextPrimary)
                    }

                    Spacer()

                    Button(action: onOpenSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.spotifyTextPrimary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Greeting and Filter Chips
                VStack(alignment: .leading, spacing: 14) {
                    Text(homeVM.greeting)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.spotifyTextPrimary)
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
                                            ? .black
                                            : .spotifyTextPrimary
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // 2-Column Quick Access Grid
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(homeVM.quickAccessTracks) { track in
                        QuickAccessCard(track: track) {
                            playerVM.play(track: track, queue: homeVM.quickAccessTracks)
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Shelves
                SectionShelfView(title: "Jump back in", tracks: homeVM.recentlyPlayed) { track in
                    playerVM.play(track: track, queue: homeVM.recentlyPlayed)
                }

                SectionShelfView(title: "Trending Right Now", tracks: homeVM.trendingHits) { track in
                    playerVM.play(track: track, queue: homeVM.trendingHits)
                }

                // Bottom spacing for miniplayer clearance
                Spacer(minLength: 80)
            }
        }
        .background(Color.spotifyBackground.ignoresSafeArea())
    }
}
