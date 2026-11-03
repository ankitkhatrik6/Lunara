import SwiftUI

public enum NavigationTab: Hashable {
    case home
    case search
    case library
}

public struct MainTabView: View {
    @State private var selectedTab: NavigationTab = .home
    @State private var playerVM = PlayerViewModel()
    @State private var homeVM = HomeViewModel()
    @State private var searchVM = SearchViewModel()
    @State private var libraryVM = LibraryViewModel()
    @State private var isSettingsPresented: Bool = false
    @State private var isFullScreenPresented: Bool = false

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(homeVM: homeVM, playerVM: playerVM) {
                    isSettingsPresented = true
                }
                .tabItem {
                    Label("Home", systemImage: selectedTab == .home ? "house.fill" : "house")
                }
                .tag(NavigationTab.home)

                SearchView(searchVM: searchVM, playerVM: playerVM)
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .tag(NavigationTab.search)

                LibraryView(libraryVM: libraryVM, playerVM: playerVM)
                    .tabItem {
                        Label("Library", systemImage: selectedTab == .library ? "books.vertical.fill" : "books.vertical")
                    }
                    .tag(NavigationTab.library)
            }
            .tint(Color.spotifyGreen)

            // Floating MiniPlayer docked directly above system TabBar
            if playerVM.isMiniPlayerVisible {
                MiniPlayerView(playerVM: playerVM)
                    .padding(.bottom, 54)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.spotifyBackground.ignoresSafeArea())
        .fullScreenCover(isPresented: $isFullScreenPresented) {
            FullScreenPlayerView(playerVM: playerVM)
        }
        .onChange(of: playerVM.isFullScreenPresented) { _, isPresented in
            isFullScreenPresented = isPresented
        }
        .onChange(of: isFullScreenPresented) { _, isPresented in
            if !isPresented {
                playerVM.isFullScreenPresented = false
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView()
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.spotifyElevatedSurface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
