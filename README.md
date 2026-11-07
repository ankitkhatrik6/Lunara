# Lunara for iOS

Lunara for iOS is a native, minimalist Spotify-inspired music streaming application built using SwiftUI (iOS 17+) and AVQueuePlayer. It matches the Android version exactly — same design system, dark/light mode, logo, home, search, library, settings, and player.

## Design System

- **Dark Mode**: `#121212` background, `#181818` elevated, `#242424` cards, `#282828` dividers
- **Light Mode**: `#FFFFFF` background, `#F4F4F4` elevated, `#EAEAEA` cards, `#D4D4D4` dividers
- **Brand Green**: `#1ED760` (Spotify green, constant across themes)
- **Text**: White in dark, `#121212` in light; secondary `#B3B3B3` / `#535353`

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
- **System Integration**:
  - `MPNowPlayingInfoCenter` for Lock Screen artwork, track title, artist, elapsed time, and scrubber duration.
  - `MPRemoteCommandCenter` for Control Center and headphone controls (Play, Pause, Skip, Previous, Seek).

## Screens

- **Home**: Dynamic greeting, filter chips (All/Music), 2-column quick access grid, horizontal shelves
- **Search**: Search bar, browse genre tiles, live search results
- **Library**: Filter pills, Liked Songs, custom playlists, playlist creation sheet
- **Player**: Docked MiniPlayer, full-screen player with album artwork, progress scrubber, lyrics sheet
- **Settings**: Dark/Light mode, Pure Black toggle, audio quality (256 kbps), cache cleaner
- **Settings**: Last.fm scrobbling integration

## CI/CD

- **iOS IPA**: Unsigned archive for sideloading via Xcode on macOS runner
- **Android APK**: Debug and Release builds via Gradle on Ubuntu runner
- Artifacts are available in the GitHub Actions run summary for 14 days.

## Versioning

- iOS and Android versioning is independent
- Tags follow `ios-*` pattern for releases

---

## CI/CD

- **iOS Builds**: GitHub Actions macOS runner, `iphoneos` SDK, unsigned IPA
- **Android Builds**: GitHub Actions Ubuntu runner, Gradle
- **Releases**: Published to [lunara-releases](https://github.com/ankitkhatrik6/lunara-releases) on `ios-*` tags

---

## Badges

[![Lunara iOS](https://img.shields.io/badge/Lunara-1.1.0-1ED760.svg?logo=app-store&labelColor=121212&color=1ED760)](https://github.com/ankitkhatrik6/lunara-releases/releases/tag/ios-1.1.0)
[![iOS Build](https://img.shields.io/github/actions/workflow/status/ankitkhatrik6/Lunara/ios-release.yml?branch=master&label=iOS%20Build&color=1ED760&labelColor=121212)](https://github.com/ankitkhatrik6/Lunara/actions/workflows/ios-release.yml)
[![Android Build](https://img.shields.io/github/actions/workflow/status/ankitkhatrik6/Lunara/android-release.yml?label=Android%20Build&color=1ED760&labelColor=121212)](https://github.com/ankitkhatrik6/Lunara/actions/workflows/android-release.yml)
