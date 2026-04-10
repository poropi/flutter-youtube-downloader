# YouTube Downloader

A Flutter desktop app that downloads YouTube videos as **MP4** or **MP3** by simply entering a URL.

> **Supported Platforms**: macOS (primary) / Windows / Linux

> [!WARNING]
> As of April 5, 2026, downloading is confirmed to work. However, future YouTube specification changes may break functionality. Please be aware of this limitation.

**[日本語版 README はこちら](README.ja.md)**

---

## Features

| Feature | Description |
|---------|-------------|
| Video Info Fetch | Retrieve title, author, and duration with preview |
| MP4 Download | Highest quality with ffmpeg (separate video+audio merged), or up to 360p without ffmpeg |
| MP3 Download | Converted to 192kbps / 44.1kHz with ffmpeg, or saved as original container (.m4a) without ffmpeg |
| Real-time Log | Download progress and processing steps displayed with timestamps |
| Open Folder | Open the Downloads folder in Finder (macOS) after completion |

---

## Requirements

### Flutter SDK

```
Flutter 3.x or later (Dart 3.9 or later)
```

Installation: https://docs.flutter.dev/get-started/install

### ffmpeg (optional, recommended)

The app works without ffmpeg, but it is required for high-quality downloads and MP3 conversion.

```bash
# macOS (Homebrew)
brew install ffmpeg

# Windows (Winget)
winget install ffmpeg

# Linux (apt)
sudo apt install ffmpeg
```

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
  ├── Fetches streams via youtube_explode_dart
  └── Calls Process.run(ffmpeg) for conversion/merging (only during download)
Model (models/)
  └── Pure data classes and enumerations
```

> ffmpeg detection at startup uses `File.existsSync()` against fixed paths only. `Process.run` is called only after the user initiates a download.

---

## Packages

| Package | Version | Purpose |
|---------|---------|---------|
| [youtube_explode_dart](https://pub.dev/packages/youtube_explode_dart) | ^3.0.5 | YouTube video info & stream fetching |
| [path_provider](https://pub.dev/packages/path_provider) | ^2.1.5 | Resolving the Downloads directory path |

---

## Troubleshooting

### Download does not start / returns an error

- Check that the URL is a valid YouTube video URL
- Check your network connection
- If the issue is caused by a YouTube specification change, upgrading `youtube_explode_dart` may resolve it

### Saved as .m4a instead of .mp3

- ffmpeg is not installed. Run `brew install ffmpeg` and restart the app
- If ffmpeg was installed via a method other than Homebrew, verify the executable exists at one of: `/opt/homebrew/bin/ffmpeg`, `/usr/local/bin/ffmpeg`, `/opt/local/bin/ffmpeg`, or `/usr/bin/ffmpeg`

### "Operation not permitted" error on macOS

- Verify that `com.apple.security.app-sandbox` is `<false/>` in `macos/Runner/DebugProfile.entitlements`
