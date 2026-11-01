import SwiftUI

// MARK: - Design Tokens (exact match to Android Theme.kt palette)

public enum LunaraTheme {
    public static let green = Color(red: 30 / 255.0, green: 215 / 255.0, blue: 96 / 255.0)      // #1ED760
    public static let greenHover = Color(red: 31 / 255.0, green: 223 / 255.0, blue: 100 / 255.0) // #1FDF64
    public static let deepBlack = Color(red: 0, green: 0, blue: 0)                              // #000000
    public static let black = Color(red: 18 / 255.0, green: 18 / 255.0, blue: 18 / 255.0)        // #121212
    public static let elevated = Color(red: 24 / 255.0, green: 24 / 255.0, blue: 24 / 255.0)     // #181818
    public static let card = Color(red: 36 / 255.0, green: 36 / 255.0, blue: 36 / 255.0)         // #242424
    public static let pill = Color(red: 42 / 255.0, green: 42 / 255.0, blue: 42 / 255.0)         // #2A2A2A
    public static let textSecondary = Color(red: 179 / 255.0, green: 179 / 255.0, blue: 179 / 255.0) // #B3B3B3
    public static let divider = Color(red: 40 / 255.0, green: 40 / 255.0, blue: 40 / 255.0)      // #282828
    public static let likedPurple = Color(red: 81 / 255.0, green: 56 / 255.0, blue: 172 / 255.0) // #5138AC
}

// MARK: - Theme-aware color accessors (matches Android's dark/light scheme)

public extension Color {
    /// Background surface — pure black in dark, white in light
    static var spotifyBackground: Color {
        @Environment(\.colorScheme) var scheme
        return scheme == .dark ? LunaraTheme.black : Color.white
    }
    /// Elevated surface (bars, headers)
    static var spotifyElevatedSurface: Color {
        @Environment(\.colorScheme) var scheme
        return scheme == .dark ? LunaraTheme.elevated : Color(red: 244 / 255.0, green: 244 / 255.0, blue: 244 / 255.0)
    }
    /// Card surface
    static var spotifyCardSurface: Color {
        @Environment(\.colorScheme) var scheme
        return scheme == .dark ? LunaraTheme.card : Color(red: 234 / 255.0, green: 234 / 255.0, blue: 234 / 255.0)
    }
    /// Pill / highest surface
    static var spotifyPillSurface: Color {
        @Environment(\.colorScheme) var scheme
        return scheme == .dark ? LunaraTheme.pill : Color(red: 223 / 255.0, green: 223 / 255.0, blue: 223 / 255.0)
    }
    /// Primary text
    static var spotifyTextPrimary: Color {
        @Environment(\.colorScheme) var scheme
        return scheme == .dark ? Color.white : Color(red: 18 / 255.0, green: 18 / 255.0, blue: 18 / 255.0)
    }
    /// Secondary text
    static var spotifyTextSecondary: Color {
        @Environment(\.colorScheme) var scheme
        return scheme == .dark ? LunaraTheme.textSecondary : Color(red: 83 / 255.0, green: 83 / 255.0, blue: 83 / 255.0)
    }
    /// Muted text
    static var spotifyTextMuted: Color {
        @Environment(\.colorScheme) var scheme
        return scheme == .dark ? LunaraTheme.textSecondary.opacity(0.7) : Color(red: 107 / 255.0, green: 107 / 255.0, blue: 107 / 255.0)
    }
    /// Divider
    static var spotifyDivider: Color {
        @Environment(\.colorScheme) var scheme
        return scheme == .dark ? LunaraTheme.divider : Color(red: 212 / 255.0, green: 212 / 255.0, blue: 212 / 255.0)
    }
    /// Spotify green (brand accent, constant across themes)
    static var spotifyGreen: Color { LunaraTheme.green }
    /// Liked songs purple
    static var spotifyLikedPurple: Color { LunaraTheme.likedPurple }
}
