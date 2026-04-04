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
  String get ffmpegDetected =>
      'ffmpeg detected  ·  High-quality MP4 / MP3 conversion supported';

  @override
  String get ffmpegNotDetected =>
      'ffmpeg not detected  ·  MP4 up to 360p / audio saved as .m4a';

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
  String get openFolderButton => 'Open folder';

  @override
  String get resetButton => 'Start over';

  @override
  String get logPanelTitle => 'Processing log';

  @override
  String savedPath(String path) {
    return 'Saved to: $path';
  }

  @override
  String get formatMp3Subtitle => 'Audio only';

  @override
  String get formatMp4Subtitle => 'Video + Audio';

  @override
  String get statusFetching => 'Fetching video info...';

  @override
  String get statusFetchSuccess => 'Video info retrieved';

  @override
  String get statusUrlInvalid => 'Invalid URL or video not found';

  @override
  String get statusDownloading => 'Downloading...';

  @override
  String get statusDownloadingAudio => 'Downloading audio...';

  @override
  String get statusMerging => 'Merging with ffmpeg...';

  @override
  String get statusConvertingMp3 => 'Converting to MP3...';

  @override
  String get statusDone => 'Done!';

  @override
  String get statusDoneNoFfmpegMp4 =>
      'Done! (Up to 360p — install ffmpeg for higher quality)\nbrew install ffmpeg';

  @override
  String statusDoneNoFfmpegMp3(String ext) {
    return 'Done! (Saved as .$ext — ffmpeg not found)\nFor MP3: brew install ffmpeg';
  }

  @override
  String statusError(String message) {
    return 'Error: $message';
  }

  @override
  String get labelVideo => 'Video';

  @override
  String get labelAudio => 'Audio';

  @override
  String get logFetchingInfo => 'Fetching video info with YoutubeExplode v3...';

  @override
  String logFetchSuccess(String title) {
    return 'Retrieved: \"$title\"';
  }

  @override
  String logError(String message) {
    return 'Error: $message';
  }

  @override
  String get logFetchingManifest => 'Fetching stream manifest...';

  @override
  String get logUsingClients => 'ytClients: [safari, androidVr]';

  @override
  String get logManifestReady => 'Manifest retrieved';

  @override
  String get logHighQualityMode =>
      'ffmpeg found → High quality mode (separate video+audio streams)';

  @override
  String logVideoStream(String quality, String codec) {
    return 'Video: $quality ($codec)';
  }

  @override
  String logAudioStream(String bitrate) {
    return 'Audio: ${bitrate}kbps';
  }

  @override
  String get logStartVideoDownload => 'Starting video download...';

  @override
  String get logStartAudioDownload => 'Starting audio download...';

  @override
  String get logMerging => 'Merging with ffmpeg...';

  @override
  String logFfmpegError(String stderr) {
    return 'ffmpeg error: $stderr';
  }

  @override
  String get logNoFfmpegMuxed =>
      'ffmpeg not found → Using muxed stream (up to 360p)';

  @override
  String logQuality(String quality) {
    return 'Quality: $quality';
  }

  @override
  String logMp4Done(String path) {
    return 'MP4 complete: $path';
  }

  @override
  String logAudioInfo(String bitrate, String ext) {
    return 'Audio: ${bitrate}kbps ($ext)';
  }

  @override
  String get logConvertingMp3 => 'Converting to MP3 with ffmpeg...';

  @override
  String logMp3Done(String path) {
    return 'MP3 complete: $path';
  }

  @override
  String logNoFfmpegSaving(String ext) {
    return 'ffmpeg not found → Saving as .$ext';
  }

  @override
  String logDownloadStart(String label, String size) {
    return '[$label] Starting download (total: $size MB)';
  }

  @override
  String logDownloadProgress(String label, String received, String total) {
    return '$label downloading... $received / $total MB';
  }

  @override
  String logDownloadDone(String label) {
    return '[$label] Download complete';
  }
}
