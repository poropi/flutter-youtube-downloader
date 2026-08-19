import 'dart:convert';
import 'dart:io';

import '../models/enums.dart';
import '../models/video_info.dart';
import 'external_tools.dart';

/// 進捗行の先頭に付ける識別子。`--progress-template` で指定する。
const progressMarker = 'YTDLP_PROGRESS|';

/// 保存先パス行の先頭に付ける識別子。`--print after_move:` で指定する。
const savedPathMarker = 'YTDLP_PATH|';

/// yt-dlp が今どの段階にいるか。
enum YtDlpStage {
  /// ストリームを受信中。
  downloading,

  /// ffmpeg で MP3 に変換中。
  converting,

  /// ffmpeg で映像と音声をマージ中。
  merging,
}

/// yt-dlp の進捗行 1 行分をパースした結果。
class DownloadProgress {
  /// yt-dlp の `progress.status`（`downloading` / `finished`）。
  final String status;

  /// 受信済みバイト数。
  final int downloadedBytes;

  /// 合計バイト数。yt-dlp が `NA` を返した場合は `null`。
  final int? totalBytes;

  const DownloadProgress({
    required this.status,
    required this.downloadedBytes,
    this.totalBytes,
  });

  /// 0.0〜1.0 の進捗率。合計バイト数が不明なら `null`。
  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return (downloadedBytes / total).clamp(0.0, 1.0);
  }
}

/// `YTDLP_PROGRESS|<status>|<downloaded>|<total>` 形式の行をパースする。
///
/// 進捗行でない場合や項目数が足りない場合は `null` を返す。
DownloadProgress? parseProgressLine(String line) {
  if (!line.startsWith(progressMarker)) return null;
  final parts = line.substring(progressMarker.length).split('|');
  if (parts.length < 3) return null;
  final downloaded = int.tryParse(parts[1]);
  if (downloaded == null) return null;
  return DownloadProgress(
    status: parts[0],
    downloadedBytes: downloaded,
    totalBytes: int.tryParse(parts[2]),
  );
}

/// `YTDLP_PATH|<path>` 形式の行から保存先パスを取り出す。
///
/// パス自体に `|` が含まれても壊れないよう、識別子より後ろを全て返す。
String? parseSavedPath(String line) {
  if (!line.startsWith(savedPathMarker)) return null;
  return line.substring(savedPathMarker.length);
}

/// yt-dlp の通常出力から処理段階を判定する。該当しなければ `null`。
YtDlpStage? parseStage(String line) {
  if (line.startsWith('[download] Destination:')) return YtDlpStage.downloading;
  if (line.startsWith('[ExtractAudio]')) return YtDlpStage.converting;
  if (line.startsWith('[Merger]')) return YtDlpStage.merging;
  return null;
}

/// 出力行のうち最初の `ERROR:` 行の本文を返す。無ければ `null`。
String? extractErrorMessage(List<String> lines) {
  for (final line in lines) {
    if (line.startsWith('ERROR:')) {
      return line.substring('ERROR:'.length).trim();
    }
  }
  return null;
}

/// MP4 用のフォーマットセレクタ。
///
/// h264 (avc1) を最優先する。無指定だと YouTube は AV1 の 4K を返すことがあり、
/// QuickTime など標準プレイヤーで再生できないファイルになるため。
const _mp4FormatSelector =
    'bv*[vcodec^=avc1][ext=mp4]+ba[ext=m4a]/bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b';

/// `web_embedded` クライアントを明示指定する引数。
///
/// 2026-08 時点で、これを指定しないと yt-dlp は android_vr 等のクライアントを選び、
/// ストリーム取得が HTTP 403 になる。
const _embeddedClientArgs = ['--extractor-args', 'youtube:player_client=web_embedded'];

/// 動画情報取得（`--dump-single-json`）用の引数を組み立てる。
List<String> buildInfoArgs(String url, {required bool useEmbeddedClient}) => [
      if (useEmbeddedClient) ..._embeddedClientArgs,
      '--dump-single-json',
      '--no-playlist',
      '--no-warnings',
      url,
    ];

/// ダウンロード用の引数を組み立てる。
///
/// - [format]             : MP3 なら音声抽出、MP4 なら映像+音声マージ。
/// - [outputDir]          : 保存先ディレクトリ。
/// - [ffmpegPath]         : 検出済み ffmpeg のフルパス。
/// - [useEmbeddedClient]  : `false` にすると `web_embedded` 指定を外す（フォールバック用）。
List<String> buildDownloadArgs({
  required String url,
  required OutputFormat format,
  required String outputDir,
  required String ffmpegPath,
  required bool useEmbeddedClient,
}) =>
    [
      if (useEmbeddedClient) ..._embeddedClientArgs,
      '--ffmpeg-location', ffmpegPath,
      '--no-playlist',
      '--no-part',
      '--newline',
      // --print は既定で他の出力を抑制してしまうため打ち消す。
      '--no-quiet',
      '--progress-template',
      '$progressMarker%(progress.status)s|%(progress.downloaded_bytes)s|%(progress.total_bytes)s',
      '--print', 'after_move:$savedPathMarker%(filepath)s',
      '-o', '$outputDir/%(title).80B.%(ext)s',
      if (format == OutputFormat.mp3) ...[
        '-x',
        '--audio-format', 'mp3',
        '--audio-quality', '192K',
      ] else ...[
        '-f', _mp4FormatSelector,
        '--merge-output-format', 'mp4',
      ],
      url,
    ];

/// yt-dlp を子プロセスとして起動し、動画情報の取得とダウンロードを行う。
class YtDlpService {
  /// 検出済みの外部コマンド。
  final ExternalTools tools;

  const YtDlpService(this.tools);

  /// 動画のメタ情報を取得する。
  ///
  /// `web_embedded` で失敗した場合はクライアント指定なしで 1 回だけ再試行する。
  /// 埋め込みが無効化されている動画のためのフォールバック。
  Future<VideoInfo> fetchInfo(String url) async {
    final ytDlp = _requireYtDlp();
    for (final useEmbedded in [true, false]) {
      final result = await Process.run(
        ytDlp,
        buildInfoArgs(url, useEmbeddedClient: useEmbedded),
      );
      if (result.exitCode == 0) {
        final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
        return VideoInfo.fromYtDlpJson(json);
      }
      if (!useEmbedded) {
        final lines = result.stderr.toString().split('\n');
        throw YtDlpException(
          extractErrorMessage(lines) ?? 'yt-dlp exited with ${result.exitCode}',
        );
      }
    }
    throw StateError('unreachable');
  }

  /// 動画をダウンロードし、保存されたファイルのフルパスを返す。
  ///
  /// `web_embedded` で失敗した場合はクライアント指定なしで 1 回だけ再試行する。
  ///
  /// - [onProgress] : 進捗行を受信したときに呼ばれる。
  /// - [onStage]    : 処理段階が変わったときに呼ばれる。
  /// - [onLog]      : yt-dlp の出力行をそのまま渡す。ログ表示用。
  Future<String> download({
    required String url,
    required OutputFormat format,
    required String outputDir,
    void Function(DownloadProgress progress)? onProgress,
    void Function(YtDlpStage stage)? onStage,
    void Function(String line, {bool isError})? onLog,
  }) async {
    final ytDlp = _requireYtDlp();
    final ffmpeg = tools.ffmpegPath;
    if (ffmpeg == null) throw const YtDlpException('ffmpeg not found');

    Object? lastError;
    for (final useEmbedded in [true, false]) {
      if (!useEmbedded) {
        onLog?.call('Retrying without the web_embedded client...', isError: false);
      }
      try {
        return await _runDownload(
          ytDlp: ytDlp,
          args: buildDownloadArgs(
            url: url,
            format: format,
            outputDir: outputDir,
            ffmpegPath: ffmpeg,
            useEmbeddedClient: useEmbedded,
          ),
          onProgress: onProgress,
          onStage: onStage,
          onLog: onLog,
        );
      } on YtDlpException catch (e) {
        lastError = e;
      }
    }
    throw lastError!;
  }

  Future<String> _runDownload({
    required String ytDlp,
    required List<String> args,
    void Function(DownloadProgress progress)? onProgress,
    void Function(YtDlpStage stage)? onStage,
    void Function(String line, {bool isError})? onLog,
  }) async {
    final process = await Process.start(
      ytDlp,
      args,
      // 検出した JS ランタイムのディレクトリを PATH に足す。
      // Finder 起動時の PATH には Homebrew が含まれないため、
      // これが無いと yt-dlp が deno を見つけられず署名解読に失敗する。
      environment: _childEnvironment(),
    );

    String? savedPath;
    YtDlpStage? stage;
    final errorLines = <String>[];

    void handleLine(String line, {required bool fromStderr}) {
      if (line.isEmpty) return;

      final progress = parseProgressLine(line);
      if (progress != null) {
        onProgress?.call(progress);
        return;
      }

      final path = parseSavedPath(line);
      if (path != null) {
        savedPath = path;
        return;
      }

      final newStage = parseStage(line);
      if (newStage != null && newStage != stage) {
        stage = newStage;
        onStage?.call(newStage);
      }

      final isError = line.startsWith('ERROR:');
      if (isError || fromStderr) errorLines.add(line);
      onLog?.call(line, isError: isError);
    }

    final stdoutDone = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((l) => handleLine(l, fromStderr: false));
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((l) => handleLine(l, fromStderr: true));

    final exitCode = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);

    if (exitCode != 0) {
      throw YtDlpException(
        extractErrorMessage(errorLines) ?? 'yt-dlp exited with $exitCode',
      );
    }
    final path = savedPath;
    if (path == null) {
      throw const YtDlpException('yt-dlp did not report the saved file path');
    }
    return path;
  }

  /// 子プロセスに渡す環境変数。JS ランタイムのディレクトリを `PATH` に追加する。
  Map<String, String> _childEnvironment() {
    final runtime = tools.jsRuntimePath;
    if (runtime == null) return {};
    final dir = File(runtime).parent.path;
    final separator = Platform.isWindows ? ';' : ':';
    final current = Platform.environment['PATH'] ?? '';
    if (current.split(separator).contains(dir)) return {};
    return {'PATH': current.isEmpty ? dir : '$dir$separator$current'};
  }

  String _requireYtDlp() {
    final path = tools.ytDlpPath;
    if (path == null) throw const YtDlpException('yt-dlp not found');
    return path;
  }
}

/// yt-dlp の実行が失敗したことを表す例外。
class YtDlpException implements Exception {
  /// 表示用のエラーメッセージ。yt-dlp の `ERROR:` 行の本文が入る。
  final String message;

  const YtDlpException(this.message);

  @override
  String toString() => message;
}
