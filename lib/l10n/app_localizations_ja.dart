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
  String get ffmpegDetected => 'ffmpeg 検出済み  ·  高画質 MP4 / MP3 変換 対応';

  @override
  String get ffmpegNotDetected => 'ffmpeg 未検出  ·  MP4 は最大 360p / 音声は .m4a 保存';

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
  String get statusDownloadingAudio => '音声をダウンロード中...';

  @override
  String get statusMerging => 'ffmpeg でマージ中...';

  @override
  String get statusConvertingMp3 => 'MP3 変換中...';

  @override
  String get statusDone => '完了！';

  @override
  String get statusDoneNoFfmpegMp4 =>
      '完了！（ffmpeg が無いため最大 360p）\n高画質は brew install ffmpeg で有効化できます';

  @override
  String statusDoneNoFfmpegMp3(String ext) {
    return '完了！（ffmpeg 未検出のため .$ext で保存）\nMP3 変換は brew install ffmpeg で有効化できます';
  }

  @override
  String statusError(String message) {
    return 'エラー: $message';
  }

  @override
  String get labelVideo => '映像';

  @override
  String get labelAudio => '音声';

  @override
  String get logFetchingInfo => 'YoutubeExplode v3 で動画情報を取得中...';

  @override
  String logFetchSuccess(String title) {
    return '取得完了: 「$title」';
  }

  @override
  String logError(String message) {
    return 'エラー: $message';
  }

  @override
  String get logFetchingManifest => 'ストリームマニフェスト取得中...';

  @override
  String get logUsingClients => 'ytClients: [safari, androidVr] を使用';

  @override
  String get logManifestReady => 'マニフェスト取得完了';

  @override
  String get logHighQualityMode => 'ffmpeg あり → 高画質モード（映像+音声を別取得）';

  @override
  String logVideoStream(String quality, String codec) {
    return '映像: $quality ($codec)';
  }

  @override
  String logAudioStream(String bitrate) {
    return '音声: ${bitrate}kbps';
  }

  @override
  String get logStartVideoDownload => '映像ダウンロード開始...';

  @override
  String get logStartAudioDownload => '音声ダウンロード開始...';

  @override
  String get logMerging => 'ffmpeg マージ中...';

  @override
  String logFfmpegError(String stderr) {
    return 'ffmpeg エラー: $stderr';
  }

  @override
  String get logNoFfmpegMuxed => 'ffmpeg なし → muxed ストリーム（最大 360p）を使用';

  @override
  String logQuality(String quality) {
    return '品質: $quality';
  }

  @override
  String logMp4Done(String path) {
    return 'MP4 完成: $path';
  }

  @override
  String logAudioInfo(String bitrate, String ext) {
    return '音声: ${bitrate}kbps ($ext)';
  }

  @override
  String get logConvertingMp3 => 'ffmpeg で MP3 変換中...';

  @override
  String logMp3Done(String path) {
    return 'MP3 完成: $path';
  }

  @override
  String logNoFfmpegSaving(String ext) {
    return 'ffmpeg なし → .$ext で保存';
  }

  @override
  String logDownloadStart(String label, String size) {
    return '[$label] 受信開始（合計: $size MB）';
  }

  @override
  String logDownloadProgress(String label, String received, String total) {
    return '$label ダウンロード中... $received / $total MB';
  }

  @override
  String logDownloadDone(String label) {
    return '[$label] ダウンロード完了';
  }
}
