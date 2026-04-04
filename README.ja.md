# YouTube Downloader

YouTube の URL を入力するだけで、動画を **MP4** または **MP3** としてダウンロードできる Flutter デスクトップアプリです。

> **対応プラットフォーム**: macOS（主対象）/ Windows / Linux

> [!WARNING]
> 2026年4月5日現在ではダウンロード可能ですが、この先 YouTube の仕様変更によりダウンロードできなくなる可能性があります。あらかじめご了承ください。

**[English README is here](README.md)**

---

## 機能

| 機能 | 説明 |
|------|------|
| 動画情報取得 | タイトル・投稿者・再生時間を取得してプレビュー表示 |
| MP4 ダウンロード | ffmpeg があれば最高画質（映像+音声を個別取得してマージ）、なければ最大 360p |
| MP3 ダウンロード | ffmpeg があれば 192kbps・44.1kHz に変換、なければ元コンテナ（.m4a）で保存 |
| リアルタイムログ | ダウンロード進捗・処理ステップをタイムスタンプ付きで画面に表示 |
| 保存先を開く | 完了後にダウンロードフォルダを Finder（macOS）で開く |

---

## 必要な環境

### Flutter SDK

```
Flutter 3.x 以上（Dart 3.9 以上）
```

インストール方法: https://docs.flutter.dev/get-started/install

### ffmpeg（任意・推奨）

ffmpeg がインストールされていない場合でも動作しますが、高画質ダウンロードや MP3 変換には必要です。

```bash
# macOS（Homebrew）
brew install ffmpeg

# Windows（Winget）
winget install ffmpeg

# Linux（apt）
sudo apt install ffmpeg
```

---

## セットアップ

### 1. リポジトリをクローン

```bash
git clone https://github.com/poropi/flutter-youtube-downloader.git
cd flutter-youtube-downloader
```

### 2. 依存パッケージを取得

```bash
flutter pub get
```

### 3. macOS のエンタイトルメント確認

macOS では外部プロセス（ffmpeg）を起動するためにサンドボックスを無効化しています。
下記ファイルで `com.apple.security.app-sandbox` が `<false/>` になっていることを確認してください。

- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

---

## 実行方法

```bash
# デバッグモードで起動（macOS）
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

---

## ビルド方法

### macOS（.app）

```bash
flutter build macos
```

ビルド成果物: `build/macos/Build/Products/Release/youtubetomp3.app`

### Windows（.exe）

```bash
flutter build windows
```

ビルド成果物: `build/windows/x64/runner/Release/youtubetomp3.exe`

### Linux

```bash
flutter build linux
```

ビルド成果物: `build/linux/x64/release/bundle/youtubetomp3`

---

## 使い方

1. **URL を入力** — YouTube の動画 URL を入力フィールドに貼り付ける
2. **動画情報を取得**（任意） — 「動画情報を取得」ボタンでタイトル・時間を確認できる
3. **フォーマットを選択** — MP3（音声のみ）または MP4（映像+音声）を選択する
4. **ダウンロード** — 「ダウンロード」ボタンを押す
5. **完了** — ダウンロードフォルダに保存される。「保存先フォルダを開く」で確認可能

> ダウンロード中は進捗バーと処理ログがリアルタイムで更新されます。

---

## プロジェクト構成

```
lib/
├── main.dart                        # エントリポイント・テーマ設定
├── models/
│   ├── enums.dart                   # OutputFormat / DownloadState
│   ├── log_entry.dart               # ログ 1 行のデータクラス
│   └── video_info.dart              # YouTube 動画情報モデル
├── viewmodels/
│   └── downloader_viewmodel.dart    # 全ビジネスロジック（ChangeNotifier）
└── views/
    ├── downloader_page.dart         # メイン画面（View）
    └── widgets/
        ├── format_card.dart         # MP3/MP4 選択カード
        ├── video_info_card.dart     # 動画情報表示カード
        ├── status_section.dart      # 進捗バー・ステータスカード
        └── log_panel.dart           # タイムスタンプ付きログパネル
```

### アーキテクチャ（MVVM）

```
View（downloader_page.dart + widgets/）
  └── ListenableBuilder で監視
ViewModel（downloader_viewmodel.dart）
  ├── ChangeNotifier で状態変化を通知
  └── youtube_explode_dart / Process.run(ffmpeg) を呼び出す
Model（models/）
  └── 純粋なデータクラス・列挙型
```

---

## 使用パッケージ

| パッケージ | バージョン | 用途 |
|-----------|-----------|------|
| [youtube_explode_dart](https://pub.dev/packages/youtube_explode_dart) | ^3.0.5 | YouTube 動画情報・ストリーム取得 |
| [path_provider](https://pub.dev/packages/path_provider) | ^2.1.5 | Downloads ディレクトリのパス解決 |

---

## トラブルシューティング

### ダウンロードが始まらない / エラーになる

- URL が正しい YouTube の動画 URL かどうか確認してください
- ネットワーク接続を確認してください
- YouTube 側の仕様変更により動作しない場合は `youtube_explode_dart` のバージョンアップで解消することがあります

### MP3 変換されず .m4a で保存される

- ffmpeg がインストールされていません。`brew install ffmpeg` を実行してアプリを再起動してください

### macOS で「操作は許可されていません」エラーが出る

- `macos/Runner/DebugProfile.entitlements` の `com.apple.security.app-sandbox` が `<false/>` になっているか確認してください
