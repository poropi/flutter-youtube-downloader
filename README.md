# YouTube Downloader

A Flutter desktop app that downloads YouTube videos as **MP4** or **MP3** by simply entering a URL.

> **Supported Platforms**: macOS (primary) / Windows / Linux

> [!WARNING]
> As of August 20, 2026, downloading is confirmed to work. However, future YouTube specification changes may break functionality. Please be aware of this limitation.

> [!IMPORTANT]
> In August 2026 YouTube started requiring a PO Token, and pure-Dart extraction (`youtube_explode_dart`) can no longer download more than the first ~60 seconds of a stream. Downloading is therefore delegated to **yt-dlp**, which requires **yt-dlp, ffmpeg, and a JavaScript runtime** to be installed. See [Requirements](#requirements).

**[日本語版 README はこちら](README.ja.md)**

---

## Features

| Feature | Description |
|---------|-------------|
| Video Info Fetch | Retrieve title, author, and duration with preview |
| MP4 Download | Separate video+audio streams merged by ffmpeg, preferring h264 for playback compatibility |
| MP3 Download | Converted to 192kbps |
| Real-time Log | Download progress and processing steps displayed with timestamps |
| Open Folder | Open the Downloads folder in Finder (macOS) after completion |

---

## Requirements

### Flutter SDK

```
Flutter 3.x or later (Dart 3.9 or later)
```

Installation: https://docs.flutter.dev/get-started/install

### External commands (all required)

Downloading needs three commands on your machine. The app detects them at startup and shows which ones are missing.

```bash
# macOS (Homebrew)
brew install yt-dlp ffmpeg deno

# Windows (Winget)
winget install yt-dlp.yt-dlp ffmpeg DenoLand.Deno

# Linux (apt + official installer)
sudo apt install yt-dlp ffmpeg
curl -fsSL https://deno.land/install.sh | sh
```

| Command | Why it is needed |
|---------|------------------|
| `yt-dlp` | Fetches video info and downloads the streams |
| `ffmpeg` | Converts to MP3 and merges video+audio into MP4 |
| `deno` (or `node` / `bun`) | yt-dlp needs a JavaScript runtime to solve YouTube's signature challenge. Without it, yt-dlp reports `n challenge solving failed` and finds no formats |

Keep `yt-dlp` up to date (`brew upgrade yt-dlp`). When YouTube changes something, a yt-dlp update is usually the fix.

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/poropi/flutter-youtube-downloader.git
cd flutter-youtube-downloader
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. macOS entitlements check

On macOS, the app sandbox is disabled to allow calling ffmpeg.
Verify that `com.apple.security.app-sandbox` is set to `<false/>` in the following files:

- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

> **Note**: At startup, ffmpeg detection uses only `File.existsSync()` against fixed paths (e.g. `/opt/homebrew/bin/ffmpeg`) without calling `Process.run`. This avoids a macOS 26+ issue where `Process.run` causes the app to be killed when launched from Finder.

---

## Running

```bash
# Debug mode (macOS)
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

---

## Building

### macOS (.app)

```bash
flutter build macos
```

Output: `build/macos/Build/Products/Release/youtubetomp3.app`

### Windows (.exe)

```bash
flutter build windows
```

Output: `build/windows/x64/runner/Release/youtubetomp3.exe`

### Linux

```bash
flutter build linux
```

Output: `build/linux/x64/release/bundle/youtubetomp3`

---

## Usage

1. **Enter URL** — Paste a YouTube video URL into the input field
2. **Fetch video info** (optional) — Click "動画情報を取得" to preview title and duration
3. **Select format** — Choose MP3 (audio only) or MP4 (video + audio)
4. **Download** — Click the "ダウンロード" button
5. **Done** — The file is saved to your Downloads folder. Click "保存先フォルダを開く" to open it

> The progress bar and processing log update in real time during download.

---

## Project Structure

```
lib/
├── main.dart                        # Entry point & theme
├── models/
│   ├── enums.dart                   # OutputFormat / DownloadState
│   ├── log_entry.dart               # Log entry data class
│   └── video_info.dart              # YouTube video info model
├── services/
│   ├── external_tools.dart          # Detects yt-dlp / ffmpeg / JS runtime
│   └── ytdlp_service.dart           # Builds yt-dlp commands, runs them, parses progress
├── viewmodels/
│   └── downloader_viewmodel.dart    # All business logic (ChangeNotifier)
└── views/
    ├── downloader_page.dart         # Main screen (View)
    └── widgets/
        ├── format_card.dart         # MP3/MP4 selection card
        ├── video_info_card.dart     # Video info display card
        ├── status_section.dart      # Progress bar & status card
        └── log_panel.dart           # Timestamped log panel
```

### Architecture (MVVM)

```
View (downloader_page.dart + widgets/)
  └── Observed via ListenableBuilder
ViewModel (downloader_viewmodel.dart)
  ├── Notifies state changes via ChangeNotifier
  └── Delegates fetching and downloading to the services layer
Service (services/)
  ├── external_tools.dart  — locates yt-dlp / ffmpeg / JS runtime
  └── ytdlp_service.dart   — spawns yt-dlp, parses its progress and errors
Model (models/)
  └── Pure data classes and enumerations
```

> Tool detection at startup uses `File.existsSync()` against fixed paths and `PATH` only. Child processes are spawned only after the user initiates a fetch or download. This avoids a macOS 26+ issue where calling `Process.run` at startup gets a Finder-launched app killed.

> The app passes `--extractor-args "youtube:player_client=web_embedded"` to yt-dlp. Without it, yt-dlp picks a client whose stream URLs return HTTP 403. If that client fails, the app retries once without the option, which covers videos that have embedding disabled.

---

## Packages

| Package | Version | Purpose |
|---------|---------|---------|
| [path_provider](https://pub.dev/packages/path_provider) | ^2.1.5 | Resolving the Downloads directory path |
| [intl](https://pub.dev/packages/intl) | any | Localization (ja / en) |

---

## Troubleshooting

### Download does not start / returns an error

- Check the badge under the title. If a command is listed as missing, install it and restart the app
- Check that the URL is a valid YouTube video URL
- Check your network connection
- If the issue is caused by a YouTube specification change, run `brew upgrade yt-dlp` first

### `HTTP Error 403: Forbidden` in the log

- Update yt-dlp: `brew upgrade yt-dlp`
- Verify a JavaScript runtime is installed (`deno --version`). Without it yt-dlp cannot solve YouTube's signature challenge and every stream URL returns 403

### A command is installed but shown as missing

- The app searches `/opt/homebrew/bin`, `/usr/local/bin`, `/opt/local/bin`, `/usr/bin`, and every directory in `PATH`. Place the executable in one of those, or add its directory to `PATH`
- When launched from Finder, `PATH` contains only the system directories, so a command installed elsewhere is found only through the fixed paths above

### "Operation not permitted" error on macOS

- Verify that `com.apple.security.app-sandbox` is `<false/>` in `macos/Runner/DebugProfile.entitlements`
