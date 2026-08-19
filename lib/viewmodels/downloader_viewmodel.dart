import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../models/log_entry.dart';
import '../models/video_info.dart';
import '../services/external_tools.dart';
import '../services/ytdlp_service.dart';

/// ダウンロード画面の全ビジネスロジックを保持する ViewModel。
///
/// [ChangeNotifier] を継承し、状態が変化するたびに [notifyListeners] を呼び出す。
/// View 側は [ListenableBuilder] でこの ViewModel を監視し、UI を再描画する。
///
/// ## ダウンロード方式
/// 実際の取得は [YtDlpService] 経由で yt-dlp に委譲する。
/// 2026-08 に YouTube が PO Token を必須化し、純 Dart 実装
/// (youtube_explode_dart) では先頭 60 秒しか取得できなくなったため。
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

  /// 検出済みの外部コマンド。
  ExternalTools _tools = const ExternalTools();

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

  /// 必要な外部コマンドが揃っているかどうか。
  bool get toolsReady => _tools.isReady;

  /// 不足している外部コマンドの一覧。
  List<MissingTool> get missingTools => _tools.missing;

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

  /// コンストラクタ。初期化時に外部コマンドの有無をチェックする。
  DownloaderViewModel() {
    _tools = ExternalTools.detect();
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
    if (!_reportMissingTools()) return;

    _setState(DownloadState.fetching, _l10n?.statusFetching ?? 'Fetching...');
    _addLog(_l10n?.logFetchingInfo ?? 'Fetching video info with yt-dlp...');

    try {
      final info = await YtDlpService(_tools).fetchInfo(url);
      _videoInfo = info;
      _addLog(
        _l10n?.logFetchSuccess(info.title) ?? 'Retrieved: "${info.title}"',
      );
      _setState(DownloadState.idle, _l10n?.statusFetchSuccess ?? 'Done');
    } catch (e) {
      _addLog(_l10n?.logError(e.toString()) ?? 'Error: $e', isError: true);
      _setState(DownloadState.error, _l10n?.statusUrlInvalid ?? 'Invalid URL');
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
    if (!_reportMissingTools()) return;

    _progress = 0;
    _savedPath = '';
    _setState(
      DownloadState.downloading,
      _l10n?.statusDownloading ?? 'Downloading...',
    );

    try {
      final dir = await _getDownloadsDir();
      _addLog(_l10n?.logUsingClient ?? 'yt-dlp client: web_embedded');

      final path = await YtDlpService(_tools).download(
        url: url,
        format: _format,
        outputDir: dir.path,
        onProgress: _handleProgress,
        onStage: _handleStage,
        onLog: (line, {bool isError = false}) =>
            _addLog(line, isError: isError),
      );

      _savedPath = path;
      _progress = 1;
      _addLog(_l10n?.logSaved(path) ?? 'Saved: $path');
      _setState(DownloadState.done, _l10n?.statusDone ?? 'Done!');
    } catch (e) {
      _addLog(_l10n?.logError(e.toString()) ?? 'Error: $e', isError: true);
      _setState(
        DownloadState.error,
        _l10n?.statusError(e.toString()) ?? 'Error: $e',
      );
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

  // ─── 内部処理 ──────────────────────────────────────────────

  /// yt-dlp の進捗を UI に反映する。
  ///
  /// 合計サイズが不明な場合は進捗率を更新せず、受信量だけを表示する。
  void _handleProgress(DownloadProgress progress) {
    final fraction = progress.fraction;
    if (fraction != null) _progress = fraction;

    final received = _megaBytes(progress.downloadedBytes);
    final total = progress.totalBytes;
    _statusMessage = total == null
        ? (_l10n?.statusDownloadingUnknownTotal(received) ??
            'Downloading... $received MB')
        : (_l10n?.statusDownloadingProgress(received, _megaBytes(total)) ??
            'Downloading... $received / ${_megaBytes(total)} MB');
    _notify();
  }

  /// yt-dlp の処理段階を状態とステータスメッセージに反映する。
  void _handleStage(YtDlpStage stage) {
    switch (stage) {
      case YtDlpStage.downloading:
        _setState(
          DownloadState.downloading,
          _l10n?.statusDownloading ?? 'Downloading...',
        );
      case YtDlpStage.converting:
        _setState(
          DownloadState.converting,
          _l10n?.statusConvertingMp3 ?? 'Converting to MP3...',
        );
      case YtDlpStage.merging:
        _setState(
          DownloadState.converting,
          _l10n?.statusMerging ?? 'Merging with ffmpeg...',
        );
    }
  }

  /// 外部コマンドが不足していればエラー状態にして `false` を返す。
  bool _reportMissingTools() {
    final missing = _tools.missing;
    if (missing.isEmpty) return true;

    for (final tool in missing) {
      _addLog(
        _l10n?.logToolMissing(_toolName(tool), installCommand(tool)) ??
            '${_toolName(tool)} not found. Install it with: '
                '${installCommand(tool)}',
        isError: true,
      );
    }
    final names = missing.map(_toolName).join(', ');
    _setState(
      DownloadState.error,
      _l10n?.statusToolsMissing(names) ?? 'Required tools not found: $names',
    );
    return false;
  }

  /// ログ・エラー表示に使うツール名。
  String _toolName(MissingTool tool) => switch (tool) {
        MissingTool.ytDlp => 'yt-dlp',
        MissingTool.ffmpeg => 'ffmpeg',
        MissingTool.jsRuntime => _l10n?.toolJsRuntime ?? 'deno (JS runtime)',
      };

  /// バイト数を小数第1位までの MB 文字列にする。
  String _megaBytes(int bytes) => (bytes / 1024 / 1024).toStringAsFixed(1);

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
