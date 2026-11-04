import SwiftUI

public struct LookFeelSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navBarStyle: NavBarStyle = .pill
    @State private var slimNavBar: Bool = false
    @State private var gridItemSize: GridItemSize = .medium
    @State private var showHomeGreeting: Bool = true
    @State private var showHomeSearchBar: Bool = true

    public enum NavBarStyle: String, CaseIterable, Identifiable {
        case pill = "Pill"
        case gradient = "Gradient"
        case outlined = "Outlined"
        case underline = "Underline"
        public var id: String { rawValue }
    }

    public enum GridItemSize: String, CaseIterable, Identifiable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        public var id: String { rawValue }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("BOTTOM NAVIGATION").foregroundColor(.spotifyTextMuted)) {
                    Picker("Style", selection: $navBarStyle) {
                        ForEach(NavBarStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .foregroundColor(.spotifyTextPrimary)

                    Toggle("Slim Navigation Bar", isOn: $slimNavBar)
                        .foregroundColor(.spotifyTextPrimary)
                        .tint(.spotifyGreen)
                }
                .listRowBackground(Color.spotifyCardSurface)

                Section(header: Text("HOME SCREEN").foregroundColor(.spotifyTextMuted)) {
                    Picker("Quick Access Card Size", selection: $gridItemSize) {
                        ForEach(GridItemSize.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .foregroundColor(.spotifyTextPrimary)

                    Toggle("Show Greeting", isOn: $showHomeGreeting)
                        .foregroundColor(.spotifyTextPrimary)
                        .tint(.spotifyGreen)

                    Toggle("Show Search Bar", isOn: $showHomeSearchBar)
                        .foregroundColor(.spotifyTextPrimary)
                        .tint(.spotifyGreen)
                }
                .listRowBackground(Color.spotifyCardSurface)

                Section(header: Text("PLAYER STYLE").foregroundColor(.spotifyTextMuted)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Player Design")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.spotifyTextMuted)

                        HStack(spacing: 16) {
                            ForEach(PlayerDesignStyle.allCases, id: \.self) { style in
                                Button {
                                    // TODO: Apply player design
                                } label: {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.spotifyCardSurface)
                                                .frame(width: 60, height: 60)
                                            Image(systemName: style.icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(.spotifyTextPrimary)
                                        }
                                        Text(style.rawValue)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.spotifyTextSecondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.spotifyCardSurface)
            }
            .background(Color.spotifyBackground.ignoresSafeArea())
            .navigationTitle("Look & Feel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.spotifyGreen)
                }
            }
        }
    }
}

public enum PlayerDesignStyle: String, CaseIterable {
    case classic = "Classic"
    case cassette = "Cassette"
    case ring = "Ring"
    case vinyl = "Vinyl"
    case fullArt = "Full Art"

    var icon: String {
        switch self {
        case .classic: return "music.note"
        case .cassette: return "rectangle.fill"
        case .ring: return "circle.fill"
        case .vinyl: return "circle.circle.fill"
        case .fullArt: return "photo.fill"
        }
    }
}