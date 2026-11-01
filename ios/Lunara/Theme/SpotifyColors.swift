import SwiftUI

// MARK: - Design Tokens (exact match to Android Theme.kt palette)

public enum LunaraTheme {
    // Dark mode colors (Spotify default - matches Android dark theme)
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

    // Light mode colors (matches Android light theme)
    public static let lightBackground = Color.white
    public static let lightElevated = Color(red: 244 / 255.0, green: 244 / 255.0, blue: 244 / 255.0)
    public static let lightCard = Color(red: 234 / 255.0, green: 234 / 255.0, blue: 234 / 255.0)
    public static let lightPill = Color(red: 223 / 255.0, green: 223 / 255.0, blue: 223 / 255.0)
    public static let lightTextPrimary = Color(red: 18 / 255.0, green: 18 / 255.0, blue: 18 / 255.0)
    public static let lightTextSecondary = Color(red: 83 / 255.0, green: 83 / 255.0, blue: 83 / 255.0)
    public static let lightTextMuted = Color(red: 107 / 255.0, green: 107 / 255.0, blue: 107 / 255.0)
    public static let lightDivider = Color(red: 212 / 255.0, green: 212 / 255.0, blue: 212 / 255.0)
}

// MARK: - Dark mode color accessors (default, matches Android dark theme)

public extension Color {
    static var spotifyBackground: Color { LunaraTheme.black }
    static var spotifyElevatedSurface: Color { LunaraTheme.elevated }
    static var spotifyCardSurface: Color { LunaraTheme.card }
    static var spotifyPillSurface: Color { LunaraTheme.pill }
    static var spotifyTextPrimary: Color { Color.white }
    static var spotifyTextSecondary: Color { LunaraTheme.textSecondary }
    static var spotifyTextMuted: Color { LunaraTheme.textSecondary.opacity(0.7) }
    static var spotifyDivider: Color { LunaraTheme.divider }
    static var spotifyGreen: Color { LunaraTheme.green }
    static var spotifyLikedPurple: Color { LunaraTheme.likedPurple }
}

// MARK: - Light mode color accessors

public extension Color {
    static var spotifyLightBackground: Color { LunaraTheme.lightBackground }
    static var spotifyLightElevatedSurface: Color { LunaraTheme.lightElevated }
    static var spotifyLightCardSurface: Color { LunaraTheme.lightCard }
    static var spotifyLightPillSurface: Color { LunaraTheme.lightPill }
    static var spotifyLightTextPrimary: Color { LunaraTheme.lightTextPrimary }
    static var spotifyLightTextSecondary: Color { LunaraTheme.lightTextSecondary }
    static var spotifyLightTextMuted: Color { LunaraTheme.lightTextMuted }
    static var spotifyLightDivider: Color { LunaraTheme.lightDivider }
}
