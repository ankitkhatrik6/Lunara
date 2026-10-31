<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&height=220&color=22C55E&text=Lunara&fontColor=ffffff&fontSize=72&fontAlignY=38&desc=Music%20without%20accounts.%20Listening%20without%20limits.&descAlignY=60&descSize=18" alt="Lunara" width="100%" />

<br/>

**A beautiful, sign-in-free music player for Android.**
Stream the full YouTube Music catalogue, with synced lyrics, downloads, and zero accounts.

<br/>

[![Platform](https://img.shields.io/badge/PLATFORM-ANDROID-22C55E?style=for-the-badge&logo=android&logoColor=white)](https://github.com/ankitkhatrik6/lunara-releases)
[![License](https://img.shields.io/badge/LICENSE-GPL--3.0-16A34A?style=for-the-badge&logo=gnu&logoColor=white)](LICENSE)
[![UI](https://img.shields.io/badge/UI-JETPACK%20COMPOSE-15803D?style=for-the-badge&logo=jetpackcompose&logoColor=white)](#tech-stack)
[![Design](https://img.shields.io/badge/DESIGN-MATERIAL%203-4ADE80?style=for-the-badge&logo=materialdesign&logoColor=064E3B)](#tech-stack)
[![Account](https://img.shields.io/badge/ACCOUNT-NOT%20REQUIRED-052E16?style=for-the-badge&logoColor=white)](#no-login-policy)

<br/>

[![Download](https://img.shields.io/badge/DOWNLOAD-LATEST%20RELEASE-22C55E?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ankitkhatrik6/lunara-releases/releases/latest)

<br/>

[Overview](#overview) &nbsp;|&nbsp; [Features](#features) &nbsp;|&nbsp; [Screenshots](#screenshots) &nbsp;|&nbsp; [Download](#download) &nbsp;|&nbsp; [Build](#build-from-source) &nbsp;|&nbsp; [Privacy](#no-login-policy) &nbsp;|&nbsp; [License](#license)

</div>

<br/>

---

## Overview

**Lunara** is a fast, elegant, open-source music player built entirely with modern Android technologies. It gives you the YouTube Music catalogue with none of the friction: no sign-in, no account, no tracking of who you are.

Open the app and press play.

---

## Features

<table>
<tr>
<td width="50%" valign="top">

![Listening](https://img.shields.io/badge/LISTENING-22C55E?style=flat-square)

- Full **YouTube Music** catalogue via InnerTube
- Browse pages, artists, albums, and playlists
- Live **home discovery** feed
- High-quality playback powered by **Media3 / ExoPlayer**

</td>
<td width="50%" valign="top">

![Library](https://img.shields.io/badge/YOUR%20LIBRARY-16A34A?style=flat-square)

- Smart **queue**, **radio**, and **autoplay**
- Offline **downloads**
- **Local music** support
- Favorites, history, and custom playlists

</td>
</tr>
<tr>
<td width="50%" valign="top">

![Lyrics](https://img.shields.io/badge/LYRICS-15803D?style=flat-square)

- Time-synced lyrics from multiple providers:
  - Paxsenix
  - LRCLIB
  - KuGou
  - LyricsPlus
  - and related lyric modules

</td>
<td width="50%" valign="top">

![Experience](https://img.shields.io/badge/EXPERIENCE-166534?style=flat-square)

- **Compose Material 3** UI with Lunara branding
- Persistent **mini-player** and expanded player sheet
- **Wrapped** summaries: weekly, monthly, and yearly

</td>
</tr>
</table>

---

## No-Login Policy

> **Lunara never restores or uses a Google/YouTube account cookie.**

The catalogue and discovery feed operate **fully signed out**. There is nothing to log into, and no account data to leak.

<div align="center">

![Account](https://img.shields.io/badge/ACCOUNT%20REQUIRED-NEVER-22C55E?style=for-the-badge)
![Cookie](https://img.shields.io/badge/GOOGLE%20COOKIE-NEVER%20USED-16A34A?style=for-the-badge)
![Discovery](https://img.shields.io/badge/DISCOVERY%20FEED-WORKS%20SIGNED%20OUT-15803D?style=for-the-badge)

</div>

---

## Download

Public releases are published in the dedicated releases repository.

<div align="center">

[![Get Lunara](https://img.shields.io/badge/GET%20LUNARA-LUNARA--RELEASES-22C55E?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ankitkhatrik6/lunara-releases/releases/latest)

</div>

1. Open the [latest release](https://github.com/ankitkhatrik6/lunara-releases/releases/latest)
2. Download the `.apk`
3. Install it on your Android device (allow installs from your browser or file manager if prompted)

---

## Build From Source

```bash
# Clone the repository
git clone https://github.com/ankitkhatrik6/lunara.git
cd lunara

# Build a debug APK
./gradlew assembleDebug
```

The APK will be generated under `app/build/outputs/apk/`.

![Requirements](https://img.shields.io/badge/REQUIREMENTS-ANDROID%20STUDIO%20%2B%20JDK-16A34A?style=flat-square)

---

## Tech Stack

<div align="center">

![Kotlin](https://img.shields.io/badge/Kotlin-22C55E?style=for-the-badge&logo=kotlin&logoColor=white)
![Compose](https://img.shields.io/badge/Jetpack%20Compose-16A34A?style=for-the-badge&logo=jetpackcompose&logoColor=white)
![Material 3](https://img.shields.io/badge/Material%203-15803D?style=for-the-badge&logo=materialdesign&logoColor=white)
![Media3](https://img.shields.io/badge/Media3%20%2F%20ExoPlayer-166534?style=for-the-badge&logo=android&logoColor=white)
![InnerTube](https://img.shields.io/badge/YouTube%20Music%20InnerTube-14532D?style=for-the-badge&logo=youtubemusic&logoColor=white)

</div>

| Layer | Technology |
|---|---|
| Language | Kotlin |
| UI | Jetpack Compose, Material 3 |
| Playback | Media3 / ExoPlayer |
| Catalogue | YouTube Music InnerTube |
| Lyrics | Paxsenix, LRCLIB, KuGou, LyricsPlus |

---

## Contributing

Contributions, issues, and feature ideas are welcome.

1. Fork the project
2. Create your branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m "Add my feature"`
4. Push the branch: `git push origin feature/my-feature`
5. Open a Pull Request

Because Lunara is GPL-3.0, any fork or derivative must remain open source under the same license.

---

## License

Lunara is distributed under the **GNU General Public License v3.0**.
See [LICENSE](LICENSE) for the upstream attribution and fork requirements.

---

## Disclaimer

Lunara is an independent project and is not affiliated with, endorsed by, or sponsored by Google or YouTube. All trademarks belong to their respective owners.

<br/>

<div align="center">

[![Author](https://img.shields.io/badge/MADE%20BY-ANKIT%20KHATRI-22C55E?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ankitkhatrik6)
[![Star](https://img.shields.io/badge/SUPPORT-STAR%20THIS%20REPO-16A34A?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ankitkhatrik6/lunara)

<img src="https://capsule-render.vercel.app/api?type=waving&height=120&color=22C55E&section=footer" alt="" width="100%" />

</div>
