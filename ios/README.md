# Lunara for iOS (Swift & SwiftUI)

Lunara for iOS is a native, minimalist Spotify-inspired music streaming application built using modern SwiftUI (iOS 17+), `@Observable`, and `AVQueuePlayer`. It matches the Android version exactly — same design system, dark/light mode, logo, home, search, library, settings, and player.

---

## Design System (matches Android exactly)

- **Dark Mode**: `#121212` background, `#181818` elevated, `#242424` cards, `#282828` dividers
- **Light Mode**: `#FFFFFF` background, `#F4F4F4` elevated, `#EAEAEA` cards, `#D4D4D4` dividers
- **Brand Green**: `#1ED760` (Spotify green, constant across themes)
- **Text**: White in dark, `#121212` in light; secondary `#B3B3B3` / `#535353`
- **Typography**: Matching Android's Material3 type scale

---

## Architecture & Features

- **Framework**: Pure SwiftUI & Swift 5.9+ (iOS 17.0+ deployment target)
- **State Management**: Apple Observation framework (`@Observable`)
- **Audio Engine**: `AVQueuePlayer` + `AVAudioSession` (`.playback` category for background audio)
- **System Integration**:
  - `MPNowPlayingInfoCenter` for Lock Screen artwork, track title, artist, elapsed time, and scrubber duration.
  - `MPRemoteCommandCenter` for Control Center and headphone controls (Play, Pause, Skip, Previous, Seek).
- **UI Screens**:
  - **Home**: Dynamic greeting, filter chips (All/Music), 2-column quick access grid, horizontal shelves
  - **Search**: Debounced search bar, browse genre tiles, live search results
  - **Library**: Filter pills, Liked Songs, custom playlists, playlist creation sheet
  - **Player**: Docked MiniPlayer, full-screen player with album artwork, progress scrubber, lyrics sheet
  - **Settings**: Dark/Light mode, Pure Black toggle, audio quality (256 kbps), cache cleaner

---

## How to Open and Run in Xcode

### 1. Requirements
- macOS Ventura (13.5+) or macOS Sonoma (14.0+) / Sequoia (15.0+)
- Xcode 15.0+ or Xcode 16.0+

### 2. Open Project
- **Via Xcode Project**: `open ios/Lunara.xcodeproj`
- **Via Swift Package Manager**: `open ios/Package.swift`

### 3. Run on Simulator or iPhone
1. Select target **Lunara** and choose an iPhone Simulator or physical device.
2. Press **Cmd + R** to build and run.

---

## CI/CD Builds (GitHub Actions)

Pushes to `master`/`main` automatically build:

- **Android APK**: Debug and Release builds via Gradle on Ubuntu runner
- **iOS IPA**: Unsigned archive for sideloading via Xcode on macOS runner

Artifacts are available in the GitHub Actions run summary for 14 days.

---

## Project Directory Map

```
ios/
├── Lunara.xcodeproj/
│   └── project.pbxproj
├── Package.swift
├── README.md
└── Lunara/
    ├── App/
    │   ├── LunaraApp.swift
    │   └── Info.plist
    ├── Theme/
    │   ├── SpotifyColors.swift
    │   └── SpotifyTypography.swift
    ├── Models/
    │   ├── Track.swift
    │   └── MusicModels.swift
    ├── Services/
    │   ├── AudioPlayerService.swift
    │   ├── YouTubeMusicService.swift
    │   └── StorageService.swift
    ├── ViewModels/
    │   ├── PlayerViewModel.swift
    │   ├── HomeViewModel.swift
    │   ├── SearchViewModel.swift
    │   └── LibraryViewModel.swift
    └── Views/
        ├── MainTabView.swift
        ├── Home/
        │   ├── HomeView.swift
        │   └── HomeComponents.swift
        ├── Search/
        │   └── SearchView.swift
        ├── Library/
        │   └── LibraryView.swift
        ├── Player/
        │   ├── MiniPlayerView.swift
        │   └── FullScreenPlayerView.swift
        └── Settings/
            └── SettingsView.swift
```
