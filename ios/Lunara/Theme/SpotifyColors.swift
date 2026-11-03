import SwiftUI

// MARK: - Design Tokens (exact match to Android Theme.kt palette)

// Raw palette (theme-independent) — matches Android Theme.kt exactly
public enum LunaraPalette {
    // Brand green — constant across both themes
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

    // Light mode colors
    public static let lightBackground = Color.white
    public static let lightSurface = Color(red: 255 / 255.0, green: 255 / 255.0, blue: 255 / 255.0)
    public static let lightSurfaceContainerHigh = Color(red: 234 / 255.0, green: 234 / 255.0, blue: 234 / 255.0)
    public static let lightSurfaceContainerHighest = Color(red: 223 / 255.0, green: 223 / 255.0, blue: 223 / 255.0)
    public static let lightTextPrimary = Color(red: 18 / 255.0, green: 18 / 255.0, blue: 18 / 255.0)
    public static let lightTextSecondary = Color(red: 83 / 255.0, green: 83 / 255.0, blue: 83 / 255.0)
    public static let lightTextMuted = Color(red: 107 / 255.0, green: 107 / 255.0, blue: 107 / 255.0)
    public static let lightDivider = Color(red: 212 / 255.0, green: 212 / 255.0, blue: 212 / 255.0)
}

// MARK: - Theme-aware color accessors

public enum LunaraTheme {
    public static var background: Color {
        Color(red: 18 / 255.0, green: 18 / 255.0, blue: 18 / 255.0)  // #121212 dark
    }
    public static var surface: Color {
        Color(red: 18 / 255.0, green: 18 / 255.0, blue: 18 / 255.0)  // #121212 dark
    }
    public static var elevatedSurface: Color {
        Color(red: 24 / 255.0, green: 24 / 255.0, blue: 24 / 255.0)  // #181818 dark
    }
    public static var cardSurface: Color {
        Color(red: 36 / 255.0, green: 36 / 255.0, blue: 36 / 255.0)  // #242424 dark
    }
    public static var pillSurface: Color {
        Color(red: 42 / 255.0, green: 42 / 255.0, blue: 42 / 255.0)  // #2A2A2A dark
    }
    public static var textPrimary: Color {
        Color.white  // dark mode
    }
    public static var textSecondary: Color {
        LunaraPalette.textSecondary
    }
    public static var textMuted: Color {
        LunaraPalette.textSecondary.opacity(0.7)
    }
    public static var divider: Color {
        LunaraPalette.divider
    }
    public static var likedSongsPurple: Color {
        LunaraPalette.likedPurple
    }
}

// MARK: - Dark mode color accessors (default — matches Android dark theme)

public extension Color {
    static var spotifyBackground: Color { LunaraTheme.background }
    static var spotifyElevatedSurface: Color { LunaraTheme.elevatedSurface }
    static var spotifyCardSurface: Color { LunaraTheme.cardSurface }
    static var spotifyPillSurface: Color { LunaraTheme.pillSurface }
    static var spotifyTextPrimary: Color { LunaraTheme.textPrimary }
    static var spotifyTextSecondary: Color { LunaraTheme.textSecondary }
    static var spotifyTextMuted: Color { LunaraTheme.textMuted }
    static var spotifyDivider: Color { LunaraTheme.divider }
    static var spotifyGreen: Color { LunaraPalette.green }
    static var spotifyLikedPurple: Color { LunaraTheme.likedSongsPurple }
}

// MARK: - Light mode color accessors

public extension Color {
    static var spotifyLightBackground: Color { LunaraPalette.lightBackground }
    static var spotifyLightSurface: Color { LunaraPalette.lightSurface }
    static var spotifyLightCardSurface: Color { LunaraPalette.lightSurfaceContainerHigh }
    static var spotifyLightPillSurface: Color { LunaraPalette.lightSurfaceContainerHighest }
    static var spotifyLightTextPrimary: Color { LunaraPalette.lightTextPrimary }
    static var spotifyLightTextSecondary: Color { LunaraPalette.lightTextSecondary }
    static var spotifyLightTextMuted: Color { LunaraPalette.lightTextMuted }
    static var spotifyLightDivider: Color { LunaraPalette.lightDivider }
}
