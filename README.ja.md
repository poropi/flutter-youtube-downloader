# YouTube Downloader

YouTube の URL を入力するだけで、動画を **MP4** または **MP3** としてダウンロードできる Flutter デスクトップアプリです。

> **対応プラットフォーム**: macOS（主対象）/ Windows / Linux

> [!WARNING]
> 2026年8月20日現在ではダウンロード可能ですが、この先 YouTube の仕様変更によりダウンロードできなくなる可能性があります。あらかじめご了承ください。

> [!IMPORTANT]
> 2026年8月に YouTube が PO Token を必須化し、純 Dart 実装（`youtube_explode_dart`）では先頭約60秒しか取得できなくなりました。そのためダウンロードは **yt-dlp** に委譲しています。**yt-dlp・ffmpeg・JavaScript ランタイム**の3つが必要です。[動作要件](#動作要件)を参照してください。

**[English README is here](README.md)**

---

## 機能

| 機能 | 説明 |
|------|------|
| 動画情報取得 | タイトル・投稿者・再生時間を取得してプレビュー表示 |
| MP4 ダウンロード | 映像+音声を個別取得して ffmpeg でマージ。再生互換性のため h264 を優先 |
| MP3 ダウンロード | 192kbps に変換 |
| リアルタイムログ | ダウンロード進捗・処理ステップをタイムスタンプ付きで画面に表示 |
| 保存先を開く | 完了後にダウンロードフォルダを Finder（macOS）で開く |

---

## 必要な環境

### Flutter SDK

```
Flutter 3.x 以上（Dart 3.9 以上）
```

インストール方法: https://docs.flutter.dev/get-started/install

### 外部コマンド（3つとも必須）

ダウンロードには次の3コマンドが必要です。アプリは起動時に検出し、不足しているものを画面に表示します。

```bash
# macOS (Homebrew)
brew install yt-dlp ffmpeg deno

# Windows (Winget)
winget install yt-dlp.yt-dlp ffmpeg DenoLand.Deno

# Linux (apt + 公式インストーラ)
sudo apt install yt-dlp ffmpeg
curl -fsSL https://deno.land/install.sh | sh
```

| コマンド | 必要な理由 |
|---------|-----------|
| `yt-dlp` | 動画情報の取得とストリームのダウンロード |
| `ffmpeg` | MP3 への変換、および映像+音声の MP4 マージ |
| `deno`（または `node` / `bun`） | yt-dlp が YouTube の署名チャレンジを解くために必要。無いと `n challenge solving failed` となりフォーマットが 0 件になる |

`yt-dlp` は最新に保ってください（`brew upgrade yt-dlp`）。YouTube 側の変更は yt-dlp の更新で直ることが多いです。

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

macOS では yt-dlp / ffmpeg を呼び出すためにサンドボックスを無効化しています。
下記ファイルで `com.apple.security.app-sandbox` が `<false/>` になっていることを確認してください。

- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

> **注意**: アプリ起動時のコマンド検出は `Process.run` を使わず、固定パス（`/opt/homebrew/bin` など）と `PATH` の存在確認のみで行います。これは macOS 26 以降の Finder 起動時に `Process.run` がプロセス終了を引き起こす問題を回避するためです。

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
├── services/
│   ├── external_tools.dart          # yt-dlp / ffmpeg / JS ランタイムの検出
│   └── ytdlp_service.dart           # yt-dlp のコマンド組み立て・実行・進捗解析
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
  └── 取得・ダウンロードを Service 層に委譲
Service (services/)
  ├── external_tools.dart  — yt-dlp / ffmpeg / JS ランタイムを検出
  └── ytdlp_service.dart   — yt-dlp を起動し、進捗とエラーを解釈
Model（models/）
  └── 純粋なデータクラス・列挙型
```

> コマンド検出（起動時）は `File.existsSync()` による固定パスと `PATH` の確認で行い、子プロセスの起動はユーザーが取得・ダウンロードを開始した後のみです。

> アプリは yt-dlp に `--extractor-args "youtube:player_client=web_embedded"` を渡します。これが無いと yt-dlp はストリーム URL が HTTP 403 になるクライアントを選びます。このクライアントで失敗した場合は指定なしで1回だけ再試行し、埋め込みが無効な動画に対応します。

---

## 使用パッケージ

| パッケージ | バージョン | 用途 |
|-----------|-----------|------|
| [intl](https://pub.dev/packages/intl) | any | 多言語対応（ja / en） |
| [path_provider](https://pub.dev/packages/path_provider) | ^2.1.5 | Downloads ディレクトリのパス解決 |

---

## トラブルシューティング

### ダウンロードが始まらない / エラーになる

- URL が正しい YouTube の動画 URL かどうか確認してください
- ネットワーク接続を確認してください
- タイトル下のバッジを確認し、不足コマンドが表示されていれば導入してアプリを再起動してください
- YouTube 側の仕様変更により動作しない場合は、まず `brew upgrade yt-dlp` を試してください

### ログに `HTTP Error 403: Forbidden` が出る

- yt-dlp を更新してください: `brew upgrade yt-dlp`
- JavaScript ランタイムが入っているか確認してください（`deno --version`）。無いと yt-dlp が署名チャレンジを解けず、全てのストリーム URL が 403 になります

### インストール済みのコマンドが「未検出」と表示される

- アプリは `/opt/homebrew/bin`・`/usr/local/bin`・`/opt/local/bin`・`/usr/bin` と `PATH` の各ディレクトリを探索します。実行ファイルをこのいずれかに置くか、そのディレクトリを `PATH` に追加してください
- Finder から起動した場合 `PATH` にはシステムディレクトリしか含まれないため、それ以外の場所に入れたコマンドは上記の固定パス経由でしか見つかりません

### macOS で「操作は許可されていません」エラーが出る

- `macos/Runner/DebugProfile.entitlements` の `com.apple.security.app-sandbox` が `<false/>` になっているか確認してください
