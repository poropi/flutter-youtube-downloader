// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'YouTube Downloader';

  @override
  String get toolsReady =>
      'yt-dlp / ffmpeg / deno detected  ·  high quality MP4 / MP3 ready';

  @override
  String toolsMissing(String tools) {
    return 'Missing: $tools  ·  downloads unavailable';
  }

  @override
  String get toolJsRuntime => 'deno (JS runtime)';

  @override
  String get urlLabel => 'YouTube URL';

  @override
  String get urlHint => 'https://www.youtube.com/watch?v=...';

  @override
  String get fetchButton => 'Fetch video info';

  @override
  String get processing => 'Processing...';

  @override
  String get downloadButton => 'Download';

  @override
  String get openFolderButton => 'Open destination folder';

  @override
  String get resetButton => 'Start over';

  @override
  String get logPanelTitle => 'Log';

  @override
  String savedPath(String path) {
    return 'Saved to: $path';
  }

  @override
  String get formatMp3Subtitle => 'Audio only';

  @override
  String get formatMp4Subtitle => 'Video + audio';

  @override
  String get statusFetching => 'Fetching video info...';

  @override
  String get statusFetchSuccess => 'Video info retrieved';

  @override
  String get statusUrlInvalid => 'Invalid URL, or the video was not found';

  @override
  String get statusDownloading => 'Downloading...';

  @override
  String statusDownloadingProgress(String received, String total) {
    return 'Downloading... $received / $total MB';
  }

  @override
  String statusDownloadingUnknownTotal(String received) {
    return 'Downloading... $received MB';
  }

  @override
  String get statusMerging => 'Merging video and audio with ffmpeg...';

  @override
  String get statusConvertingMp3 => 'Converting to MP3...';

  @override
  String get statusDone => 'Done!';

  @override
  String statusError(String message) {
    return 'Error: $message';
  }

  @override
  String statusToolsMissing(String tools) {
    return 'Required commands not found: $tools';
  }

  @override
  String get logFetchingInfo => 'Fetching video info with yt-dlp...';

  @override
  String logFetchSuccess(String title) {
    return 'Retrieved: \"$title\"';
  }

  @override
  String get logUsingClient => 'yt-dlp client: web_embedded';

  @override
  String logSaved(String path) {
    return 'Saved: $path';
  }

  @override
  String logToolMissing(String tool, String command) {
    return '$tool not found. Install it with: $command';
  }

  @override
  String logError(String message) {
    return 'Error: $message';
  }
}
