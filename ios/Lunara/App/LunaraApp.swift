import SwiftUI

@main
public struct LunaraApp: App {
    @State private var darkMode: Bool = false
    @State private var pureBlack: Bool = true

    public init() {}

    public var body: some Scene {
        WindowGroup {
            if Auth.shared.isLoggedIn {
                MainTabView()
                    .environment(\.colorScheme, darkMode ? .dark : .light)
                    .preferredColorScheme(darkMode ? .dark : .light)
            } else {
                LoginView()
            }
        }
    }
}
