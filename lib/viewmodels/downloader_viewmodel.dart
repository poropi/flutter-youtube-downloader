import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';

import '../models/enums.dart';
import '../models/log_entry.dart';
import '../models/video_info.dart';

/// ダウンロード画面の全ビジネスロジックを保持する ViewModel。
///
/// [ChangeNotifier] を継承し、状態が変化するたびに [notifyListeners] を呼び出す。
/// View 側は [ListenableBuilder] でこの ViewModel を監視し、UI を再描画する。
///
/// ## 主な責務
/// - YouTube URL から動画情報を取得する（[fetchInfo]）
/// - 指定フォーマットでダウンロードを実行する（[startDownload]）
/// - ダウンロード進捗・ステータスメッセージ・処理ログを管理する
/// - ffmpeg の有無を判定し、利用可能な場合は高画質処理を行う
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

  /// タイムスタンプ付きの処理ログ一覧。
  final List<LogEntry> _logs = [];

  /// [dispose] 後に [notifyListeners] を呼び出さないためのフラグ。
  bool _disposed = false;

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

  /// `which ffmpeg` を実行してシステムに ffmpeg があるか確認する。
  Future<void> _checkFfmpeg() async {
    try {
      final result = await Process.run('which', ['ffmpeg']);
      _ffmpegAvailable = result.exitCode == 0;
      _notify();
    } catch (_) {}
  }

  // ─── 公開メソッド（View から呼び出す） ────────────────────

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
    _setState(DownloadState.fetching, '動画情報を取得中...');
    _addLog('YoutubeExplode v3 で動画情報を取得中...');

    final yt = YoutubeExplode();
    try {
      final video = await yt.videos.get(url);
      _videoInfo = VideoInfo.fromVideo(video);
      _addLog('取得完了: 「${video.title}」');
      _setState(DownloadState.idle, '動画情報を取得しました');
    } catch (e) {
      _addLog('エラー: $e', isError: true);
      _setState(DownloadState.error, 'URLが正しくないか、動画が見つかりません');
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
    _setState(DownloadState.downloading, 'ダウンロード中...');

    final yt = YoutubeExplode();
    try {
      _addLog('ストリームマニフェスト取得中...');
      _addLog('ytClients: [safari, androidVr] を使用');

      // VideoInfo.id を使ってマニフェストを取得
      final manifest = await yt.videos.streams.getManifest(
        _videoInfo!.id,
        ytClients: [YoutubeApiClient.safari, YoutubeApiClient.androidVr],
      );
      _addLog('マニフェスト取得完了');

      final dir = await _getDownloadsDir();
      final safeTitle = _sanitizeTitle(_videoInfo!.title);

      if (_format == OutputFormat.mp4) {
        await _downloadMp4(yt, manifest, dir.path, safeTitle);
      } else {
        await _downloadMp3(yt, manifest, dir.path, safeTitle);
      }
    } catch (e, st) {
      _addLog('エラー: $e', isError: true);
      _addLog(st.toString().split('\n').first, isError: true);
      _setState(DownloadState.error, 'エラー: $e');
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
  ///
  /// - [yt]       : [YoutubeExplode] のインスタンス。
  /// - [manifest] : 取得済みのストリームマニフェスト。
  /// - [dirPath]  : 保存先ディレクトリのフルパス。
  /// - [title]    : ファイル名に使用する sanitize 済みのタイトル。
  Future<void> _downloadMp4(
    YoutubeExplode yt,
    StreamManifest manifest,
    String dirPath,
    String title,
  ) async {
    final savePath = '$dirPath/$title.mp4';

    if (_ffmpegAvailable) {
      // 高画質: 映像+音声を別々に取得して ffmpeg でマージ
      _addLog('ffmpeg あり → 高画質モード（映像+音声を別取得）');
      final videoStream = manifest.videoOnly.sortByVideoQuality().first;
      final audioStream = manifest.audioOnly.withHighestBitrate();
      _addLog(
        '映像: ${videoStream.videoQuality} (${videoStream.codec.mimeType})',
      );
      _addLog(
        '音声: ${audioStream.bitrate.kiloBitsPerSecond.toStringAsFixed(0)}kbps',
      );

      final tempVideo = '$dirPath/__tmp_video.${videoStream.container.name}';
      final tempAudio = '$dirPath/__tmp_audio.${audioStream.container.name}';

      _addLog('映像ダウンロード開始...');
      await _downloadStream(yt, videoStream, tempVideo, label: '映像');

      _progress = 0;
      _setState(DownloadState.downloading, '音声をダウンロード中...');
      _addLog('音声ダウンロード開始...');
      await _downloadStream(yt, audioStream, tempAudio, label: '音声');

      _setState(DownloadState.converting, 'ffmpeg でマージ中...');
      _addLog('ffmpeg マージ中...');

      final result = await Process.run('ffmpeg', [
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
        _addLog('ffmpeg エラー: ${result.stderr}', isError: true);
        throw Exception('ffmpeg マージ失敗（exitCode=${result.exitCode}）');
      }
    } else {
      // ffmpeg なし: muxed ストリーム（最大 360p）
      _addLog('ffmpeg なし → muxed ストリーム（最大 360p）を使用');
      final muxed = manifest.muxed.withHighestBitrate();
      _addLog('品質: ${muxed.videoQuality}');
      await _downloadStream(yt, muxed, savePath, label: 'MP4');
    }

    _addLog('MP4 完成: $savePath');
    _savedPath = savePath;
    _setState(
      DownloadState.done,
      _ffmpegAvailable
          ? '完了！'
          : '完了！（ffmpeg が無いため最大 360p）\n高画質は brew install ffmpeg で有効化できます',
    );
  }

  /// MP3 形式でダウンロードする内部処理。
  ///
  /// 音声ストリームを一時ファイルにダウンロードし、ffmpeg が利用可能であれば
  /// 192kbps・44.1kHz・ステレオの MP3 に変換する。
  /// ffmpeg がない場合は元のコンテナ形式（.m4a など）のまま保存する。
  ///
  /// - [yt]       : [YoutubeExplode] のインスタンス。
  /// - [manifest] : 取得済みのストリームマニフェスト。
  /// - [dirPath]  : 保存先ディレクトリのフルパス。
  /// - [title]    : ファイル名に使用する sanitize 済みのタイトル。
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

    _addLog(
      '音声: ${audioStream.bitrate.kiloBitsPerSecond.toStringAsFixed(0)}kbps ($tempExt)',
    );
    _addLog('音声ダウンロード開始...');
    await _downloadStream(yt, audioStream, tempPath, label: '音声');

    if (_ffmpegAvailable) {
      _setState(DownloadState.converting, 'MP3 変換中...');
      _addLog('ffmpeg で MP3 変換中...');

      final savePath = '$dirPath/$title.mp3';
      final result = await Process.run('ffmpeg', [
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
        _addLog('ffmpeg エラー: ${result.stderr}', isError: true);
        throw Exception('MP3 変換失敗（exitCode=${result.exitCode}）');
      }

      _addLog('MP3 完成: $savePath');
      _savedPath = savePath;
      _setState(DownloadState.done, '完了！');
    } else {
      _addLog('ffmpeg なし → .$tempExt で保存');
      final savePath = '$dirPath/$title.$tempExt';
      await File(tempPath).rename(savePath);
      _savedPath = savePath;
      _setState(
        DownloadState.done,
        '完了！（ffmpeg 未検出のため .$tempExt で保存）\nMP3 変換は brew install ffmpeg で有効化できます',
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
  /// - [label]      : ログ・ステータスメッセージに表示するラベル（例: "映像"）。
  Future<void> _downloadStream(
    YoutubeExplode yt,
    StreamInfo streamInfo,
    String savePath, {
    required String label,
  }) async {
    final total = streamInfo.size.totalBytes;
    _addLog(
      '[$label] 受信開始（合計: ${(total / 1024 / 1024).toStringAsFixed(1)} MB）',
    );

    final stream = yt.videos.streams.get(streamInfo);
    final sink = File(savePath).openWrite();
    int received = 0;

    await for (final chunk in stream) {
      sink.add(chunk);
      received += chunk.length;
      _progress = received / total;
      _statusMessage =
          '$label ダウンロード中... ${(received / 1024 / 1024).toStringAsFixed(1)} /'
          ' ${(total / 1024 / 1024).toStringAsFixed(1)} MB';
      _notify();
    }

    await sink.flush();
    await sink.close();
    _addLog('[$label] ダウンロード完了');
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
  ///
  /// 対象文字: `\ / : * ? " < > |`
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
  ///
  /// - [message] : ログ文字列。
  /// - [isError] : エラーレベルの場合は `true`。
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
