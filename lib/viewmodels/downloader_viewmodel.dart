import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../models/log_entry.dart';
import '../models/video_info.dart';

/// ダウンロード画面の全ビジネスロジックを保持する ViewModel。
///
/// [ChangeNotifier] を継承し、状態が変化するたびに [notifyListeners] を呼び出す。
/// View 側は [ListenableBuilder] でこの ViewModel を監視し、UI を再描画する。
///
/// ## 多言語対応
/// View の `ListenableBuilder` 内で [setL10n] を呼び出すことで
/// [AppLocalizations] インスタンスを注入し、全ての文字列を現在のロケールで生成する。
class DownloaderViewModel extends ChangeNotifier {
  // ─── 状態フィールド ────────────────────────────────────────

  /// 選択中の出力フォーマット（デフォルト: MP3）。
  OutputFormat _format = OutputFormat.mp3;

  /// 現在の処理状態。
  DownloadState _state = DownloadState.idle;

  /// ダウンロード進捗（0.0〜1.0）。
  double _progress = 0;

  /// UI に表示するステータスメッセージ。
  String _statusMessage = '';

  /// 保存完了したファイルのフルパス。未保存時は空文字。
  String _savedPath = '';

  /// 取得済みの動画情報。未取得時は `null`。
  VideoInfo? _videoInfo;

  /// システムに ffmpeg がインストールされているかどうか。
  bool _ffmpegAvailable = false;

  /// 利用可能な ffmpeg 実行ファイルのフルパス。
  String? _ffmpegExecutable;

  /// タイムスタンプ付きの処理ログ一覧。
  final List<LogEntry> _logs = [];

  /// [dispose] 後に [notifyListeners] を呼び出さないためのフラグ。
  bool _disposed = false;

  /// View から注入されるローカライゼーションインスタンス。
  AppLocalizations? _l10n;

  // ─── Getter（View から読み取り専用） ──────────────────────

  /// 選択中の出力フォーマット。
  OutputFormat get format => _format;

  /// 現在の処理状態。
  DownloadState get state => _state;

  /// ダウンロード進捗（0.0〜1.0）。変換中は使用されない。
  double get progress => _progress;

  /// UI に表示するステータスメッセージ。
  String get statusMessage => _statusMessage;

  /// ダウンロード完了ファイルのフルパス。完了前は空文字。
  String get savedPath => _savedPath;

  /// 取得済みの動画情報。[fetchInfo] 成功後に設定される。
  VideoInfo? get videoInfo => _videoInfo;

  /// ffmpeg がシステムにインストールされているかどうか。
  bool get ffmpegAvailable => _ffmpegAvailable;

  /// 処理ログの読み取り専用リスト。
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// いずれかの非同期処理が実行中であれば `true`。
  ///
  /// このフラグが `true` の間、UI はボタンを無効化して多重実行を防ぐ。
  bool get isBusy =>
      _state == DownloadState.fetching ||
      _state == DownloadState.downloading ||
      _state == DownloadState.converting;

  // ─── 初期化 ────────────────────────────────────────────────

  /// コンストラクタ。初期化時に ffmpeg の有無を非同期チェックする。
  DownloaderViewModel() {
    _checkFfmpeg();
  }

  /// macOS の代表的なインストール先を existsSync で確認する。
  /// Process.run は使わない（Finder起動時に SIGKILL を引き起こすため）。
  Future<void> _checkFfmpeg() async {
    final candidates = [
      '/opt/homebrew/bin/ffmpeg',
      '/usr/local/bin/ffmpeg',
      '/opt/local/bin/ffmpeg',
      '/usr/bin/ffmpeg',
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) {
        _ffmpegAvailable = true;
        _ffmpegExecutable = path;
        _notify();
        return;
      }
    }
    _ffmpegAvailable = false;
    _notify();
  }

  // ─── 公開メソッド（View から呼び出す） ────────────────────

  /// View のビルド時に現在のロケール情報を注入する。
  ///
  /// [ListenableBuilder] の builder 内で毎回呼び出すことで、
  /// システムロケールの変更にも追従できる。
  void setL10n(AppLocalizations l10n) => _l10n = l10n;

  /// 出力フォーマットを変更する。
  ///
  /// - [format] : 新しいフォーマット（[OutputFormat.mp3] または [OutputFormat.mp4]）。
  void setFormat(OutputFormat format) {
    if (_format == format) return;
    _format = format;
    _notify();
  }

  /// 指定した YouTube URL から動画のメタ情報を取得する。
  ///
  /// 成功すると [videoInfo] が更新される。
  /// 失敗した場合は [state] が [DownloadState.error] に遷移し、
  /// [statusMessage] にエラー内容が設定される。
  ///
  /// - [url] : YouTube の動画 URL 文字列。
  Future<void> fetchInfo(String url) async {
    if (url.isEmpty) return;

    _clearLogs();
    _setState(DownloadState.fetching, _l10n?.statusFetching ?? 'Fetching...');
    _addLog(_l10n?.logFetchingInfo ?? 'Fetching video info...');

    final yt = YoutubeExplode();
    try {
      final video = await yt.videos.get(url);
      _videoInfo = VideoInfo.fromVideo(video);
      _addLog(
        _l10n?.logFetchSuccess(video.title) ?? 'Retrieved: "${video.title}"',
      );
      _setState(DownloadState.idle, _l10n?.statusFetchSuccess ?? 'Done');
    } catch (e) {
      _addLog(_l10n?.logError(e.toString()) ?? 'Error: $e', isError: true);
      _setState(DownloadState.error, _l10n?.statusUrlInvalid ?? 'Invalid URL');
    } finally {
      yt.close();
    }
  }

  /// 指定した URL の動画を選択フォーマットでダウンロードする。
  ///
  /// [videoInfo] が未取得の場合は先に [fetchInfo] を実行する。
  /// ダウンロード完了後は [savedPath] にファイルパスが格納され、
  /// [state] が [DownloadState.done] に遷移する。
  ///
  /// - [url] : YouTube の動画 URL 文字列。
  Future<void> startDownload(String url) async {
    if (_videoInfo == null) {
      await fetchInfo(url);
      if (_videoInfo == null) return;
    }

    _clearLogs();
    _progress = 0;
    _savedPath = '';
    _setState(
      DownloadState.downloading,
      _l10n?.statusDownloading ?? 'Downloading...',
    );

    final yt = YoutubeExplode();
    try {
      _addLog(_l10n?.logFetchingManifest ?? 'Fetching manifest...');
      _addLog(_l10n?.logUsingClients ?? 'ytClients: [safari, androidVr]');

      final manifest = await yt.videos.streams.getManifest(
        _videoInfo!.id,
        ytClients: [YoutubeApiClient.safari, YoutubeApiClient.androidVr],
      );
      _addLog(_l10n?.logManifestReady ?? 'Manifest ready');

      final dir = await _getDownloadsDir();
      final safeTitle = _sanitizeTitle(_videoInfo!.title);

      if (_format == OutputFormat.mp4) {
        await _downloadMp4(yt, manifest, dir.path, safeTitle);
      } else {
        await _downloadMp3(yt, manifest, dir.path, safeTitle);
      }
    } catch (e, st) {
      _addLog(_l10n?.logError(e.toString()) ?? 'Error: $e', isError: true);
      _addLog(st.toString().split('\n').first, isError: true);
      _setState(
        DownloadState.error,
        _l10n?.statusError(e.toString()) ?? 'Error: $e',
      );
    } finally {
      yt.close();
    }
  }

  /// 全状態を初期値にリセットする。
  ///
  /// URL フィールドのクリアは View 側（[DownloaderPage]）が担当する。
  void reset() {
    _state = DownloadState.idle;
    _progress = 0;
    _statusMessage = '';
    _savedPath = '';
    _videoInfo = null;
    _logs.clear();
    _notify();
  }

  // ─── 内部ダウンロード処理 ──────────────────────────────────

  /// MP4 形式でダウンロードする内部処理。
  ///
  /// ffmpeg が利用可能な場合は映像・音声ストリームを個別取得してマージする（最高画質）。
  /// ffmpeg がない場合は muxed ストリーム（最大 360p）を直接保存する。
  Future<void> _downloadMp4(
    YoutubeExplode yt,
    StreamManifest manifest,
    String dirPath,
    String title,
  ) async {
    final savePath = '$dirPath/$title.mp4';
    final labelVideo = _l10n?.labelVideo ?? 'Video';
    final labelAudio = _l10n?.labelAudio ?? 'Audio';

    if (_ffmpegAvailable) {
      _addLog(_l10n?.logHighQualityMode ?? 'High quality mode');
      final videoStream = manifest.videoOnly.sortByVideoQuality().first;
      final audioStream = manifest.audioOnly.withHighestBitrate();
      _addLog(
        _l10n?.logVideoStream(
              videoStream.videoQuality.toString(),
              videoStream.codec.mimeType,
            ) ??
            'Video: ${videoStream.videoQuality}',
      );
      _addLog(
        _l10n?.logAudioStream(
              audioStream.bitrate.kiloBitsPerSecond.toStringAsFixed(0),
            ) ??
            'Audio: ${audioStream.bitrate.kiloBitsPerSecond.toStringAsFixed(0)}kbps',
      );

      final tempVideo = '$dirPath/__tmp_video.${videoStream.container.name}';
      final tempAudio = '$dirPath/__tmp_audio.${audioStream.container.name}';

      _addLog(_l10n?.logStartVideoDownload ?? 'Starting video download...');
      await _downloadStream(yt, videoStream, tempVideo, label: labelVideo);

      _progress = 0;
      _setState(
        DownloadState.downloading,
        _l10n?.statusDownloadingAudio ?? 'Downloading audio...',
      );
      _addLog(_l10n?.logStartAudioDownload ?? 'Starting audio download...');
      await _downloadStream(yt, audioStream, tempAudio, label: labelAudio);

      _setState(DownloadState.converting, _l10n?.statusMerging ?? 'Merging...');
      _addLog(_l10n?.logMerging ?? 'Merging...');

      final result = await Process.run(_ffmpegExecutable!, [
        '-y',
        '-i',
        tempVideo,
        '-i',
        tempAudio,
        '-c:v',
        'copy',
        '-c:a',
        'aac',
        savePath,
      ]);

      await File(tempVideo).delete().catchError((_) => File(tempVideo));
      await File(tempAudio).delete().catchError((_) => File(tempAudio));

      if (result.exitCode != 0) {
        _addLog(
          _l10n?.logFfmpegError(result.stderr.toString()) ?? 'ffmpeg error',
          isError: true,
        );
        throw Exception('ffmpeg merge failed (exitCode=${result.exitCode})');
      }
    } else {
      _addLog(_l10n?.logNoFfmpegMuxed ?? 'Using muxed stream');
      final muxed = manifest.muxed.withHighestBitrate();
      _addLog(
        _l10n?.logQuality(muxed.videoQuality.toString()) ??
            'Quality: ${muxed.videoQuality}',
      );
      await _downloadStream(yt, muxed, savePath, label: 'MP4');
    }

    _addLog(_l10n?.logMp4Done(savePath) ?? 'MP4 done: $savePath');
    _savedPath = savePath;
    _setState(
      DownloadState.done,
      _ffmpegAvailable
          ? (_l10n?.statusDone ?? 'Done!')
          : (_l10n?.statusDoneNoFfmpegMp4 ?? 'Done! (up to 360p)'),
    );
  }

  /// MP3 形式でダウンロードする内部処理。
  ///
  /// 音声ストリームを一時ファイルにダウンロードし、ffmpeg が利用可能であれば
  /// 192kbps・44.1kHz・ステレオの MP3 に変換する。
  /// ffmpeg がない場合は元のコンテナ形式（.m4a など）のまま保存する。
  Future<void> _downloadMp3(
    YoutubeExplode yt,
    StreamManifest manifest,
    String dirPath,
    String title,
  ) async {
    final audioStream = manifest.audioOnly.withHighestBitrate();
    final tempExt = audioStream.container.name == 'mp4'
        ? 'm4a'
        : audioStream.container.name;
    final tempPath = '$dirPath/__tmp_audio.$tempExt';
    final labelAudio = _l10n?.labelAudio ?? 'Audio';

    _addLog(
      _l10n?.logAudioInfo(
            audioStream.bitrate.kiloBitsPerSecond.toStringAsFixed(0),
            tempExt,
          ) ??
          'Audio: ${audioStream.bitrate.kiloBitsPerSecond.toStringAsFixed(0)}kbps ($tempExt)',
    );
    _addLog(_l10n?.logStartAudioDownload ?? 'Starting audio download...');
    await _downloadStream(yt, audioStream, tempPath, label: labelAudio);

    if (_ffmpegAvailable) {
      _setState(
        DownloadState.converting,
        _l10n?.statusConvertingMp3 ?? 'Converting to MP3...',
      );
      _addLog(_l10n?.logConvertingMp3 ?? 'Converting to MP3...');

      final savePath = '$dirPath/$title.mp3';
      final result = await Process.run(_ffmpegExecutable!, [
        '-y',
        '-i',
        tempPath,
        '-vn',
        '-ar',
        '44100',
        '-ac',
        '2',
        '-b:a',
        '192k',
        savePath,
      ]);
      await File(tempPath).delete().catchError((_) => File(tempPath));

      if (result.exitCode != 0) {
        _addLog(
          _l10n?.logFfmpegError(result.stderr.toString()) ?? 'ffmpeg error',
          isError: true,
        );
        throw Exception('MP3 conversion failed (exitCode=${result.exitCode})');
      }

      _addLog(_l10n?.logMp3Done(savePath) ?? 'MP3 done: $savePath');
      _savedPath = savePath;
      _setState(DownloadState.done, _l10n?.statusDone ?? 'Done!');
    } else {
      _addLog(_l10n?.logNoFfmpegSaving(tempExt) ?? 'Saving as .$tempExt');
      final savePath = '$dirPath/$title.$tempExt';
      await File(tempPath).rename(savePath);
      _savedPath = savePath;
      _setState(
        DownloadState.done,
        _l10n?.statusDoneNoFfmpegMp3(tempExt) ?? 'Done! (.$tempExt)',
      );
    }
  }

  /// YouTube ストリームをファイルに書き込みながら進捗を通知する。
  ///
  /// チャンクを受信するたびに [_progress] と [_statusMessage] を更新し、
  /// [notifyListeners] を呼び出して UI をリアルタイムに更新する。
  ///
  /// - [yt]         : [YoutubeExplode] のインスタンス。
  /// - [streamInfo] : ダウンロード先のストリーム情報。
  /// - [savePath]   : 書き込み先ファイルのフルパス。
  /// - [label]      : ログ・ステータスメッセージに表示するラベル（翻訳済み文字列）。
  Future<void> _downloadStream(
    YoutubeExplode yt,
    StreamInfo streamInfo,
    String savePath, {
    required String label,
  }) async {
    final total = streamInfo.size.totalBytes;
    _addLog(
      _l10n?.logDownloadStart(
            label,
            (total / 1024 / 1024).toStringAsFixed(1),
          ) ??
          '[$label] Starting (${(total / 1024 / 1024).toStringAsFixed(1)} MB)',
    );

    final stream = yt.videos.streams.get(streamInfo);
    final sink = File(savePath).openWrite();
    int received = 0;

    await for (final chunk in stream) {
      sink.add(chunk);
      received += chunk.length;
      _progress = received / total;
      _statusMessage =
          _l10n?.logDownloadProgress(
            label,
            (received / 1024 / 1024).toStringAsFixed(1),
            (total / 1024 / 1024).toStringAsFixed(1),
          ) ??
          '$label ${(received / 1024 / 1024).toStringAsFixed(1)} / ${(total / 1024 / 1024).toStringAsFixed(1)} MB';
      _notify();
    }

    await sink.flush();
    await sink.close();
    _addLog(_l10n?.logDownloadDone(label) ?? '[$label] Done');
  }

  // ─── ユーティリティ ────────────────────────────────────────

  /// OS の Downloads ディレクトリを返す。
  ///
  /// macOS / Linux は `$HOME/Downloads`、Windows は `%USERPROFILE%\Downloads` を優先する。
  /// ディレクトリが存在しない場合はアプリのドキュメントディレクトリを返す。
  Future<Directory> _getDownloadsDir() async {
    if (Platform.isMacOS || Platform.isLinux) {
      final dir = Directory('${Platform.environment['HOME']}/Downloads');
      if (await dir.exists()) return dir;
    } else if (Platform.isWindows) {
      final dir = Directory(
        '${Platform.environment['USERPROFILE']}\\Downloads',
      );
      if (await dir.exists()) return dir;
    }
    return await getApplicationDocumentsDirectory();
  }

  /// ファイル名として使用できない文字を `_` に置換し、最大 80 文字に切り詰める。
  String _sanitizeTitle(String title) => title
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .substring(0, title.length.clamp(0, 80));

  /// [_state] と [_statusMessage] を同時に更新して通知する。
  void _setState(DownloadState state, String message) {
    _state = state;
    _statusMessage = message;
    _notify();
  }

  /// ログリストを空にして通知する。
  void _clearLogs() {
    _logs.clear();
    _notify();
  }

  /// ログエントリを追加して通知する。
  void _addLog(String message, {bool isError = false}) {
    _logs.add(LogEntry(message, isError: isError));
    _notify();
  }

  /// [dispose] 後は [notifyListeners] を呼ばないガード付きの通知メソッド。
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
