// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'YouTube Downloader';

  @override
  String get toolsReady =>
      'yt-dlp / ffmpeg / deno 検出済み  ·  高画質 MP4 / MP3 変換 対応';

  @override
  String toolsMissing(String tools) {
    return '未検出: $tools  ·  ダウンロードできません';
  }

  @override
  String get toolJsRuntime => 'deno（JS ランタイム）';

  @override
  String get urlLabel => 'YouTube URL';

  @override
  String get urlHint => 'https://www.youtube.com/watch?v=...';

  @override
  String get fetchButton => '動画情報を取得';

  @override
  String get processing => '処理中...';

  @override
  String get downloadButton => 'ダウンロード';

  @override
  String get openFolderButton => '保存先フォルダを開く';

  @override
  String get resetButton => '最初に戻る';

  @override
  String get logPanelTitle => '処理ログ';

  @override
  String savedPath(String path) {
    return '保存先: $path';
  }

  @override
  String get formatMp3Subtitle => '音声のみ';

  @override
  String get formatMp4Subtitle => '映像 + 音声';

  @override
  String get statusFetching => '動画情報を取得中...';

  @override
  String get statusFetchSuccess => '動画情報を取得しました';

  @override
  String get statusUrlInvalid => 'URLが正しくないか、動画が見つかりません';

  @override
  String get statusDownloading => 'ダウンロード中...';

  @override
  String statusDownloadingProgress(String received, String total) {
    return 'ダウンロード中... $received / $total MB';
  }

  @override
  String statusDownloadingUnknownTotal(String received) {
    return 'ダウンロード中... $received MB';
  }

  @override
  String get statusMerging => 'ffmpeg で映像と音声をマージ中...';

  @override
  String get statusConvertingMp3 => 'MP3 変換中...';

  @override
  String get statusDone => '完了！';

  @override
  String statusError(String message) {
    return 'エラー: $message';
  }

  @override
  String statusToolsMissing(String tools) {
    return '必要なコマンドが見つかりません: $tools';
  }

  @override
  String get logFetchingInfo => 'yt-dlp で動画情報を取得中...';

  @override
  String logFetchSuccess(String title) {
    return '取得完了: 「$title」';
  }

  @override
  String get logUsingClient => 'yt-dlp クライアント: web_embedded';

  @override
  String logSaved(String path) {
    return '保存しました: $path';
  }

  @override
  String logToolMissing(String tool, String command) {
    return '$tool が見つかりません。$command で導入してください。';
  }

  @override
  String logError(String message) {
    return 'エラー: $message';
  }
}
