import 'dart:io';

/// デスクトップアプリ起動時のクラッシュ調査用ファイルロガー。
///
/// ~/Desktop/ytdl_debug.log にログを追記する（同期書き込み）。
class FileLogger {
  static String? _path;

  /// ロガーを初期化する（同期）。
  static void init() {
    try {
      final home = Platform.environment['HOME'] ?? '/tmp';
      _path = '$home/Desktop/ytdl_debug.log';
      log('=== APP STARTED at ${DateTime.now()} ===');
      log('OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      log('PID: $pid');
    } catch (e) {
      _writeSync('[FileLogger.init ERROR] $e');
    }
  }

  /// メッセージをログファイルに同期書き込みする。
  static void log(String message) {
    final line = '[${DateTime.now().toIso8601String()}] $message';
    stderr.writeln(line);
    _writeSync(line);
  }

  /// エラーをログファイルに書き込む。
  static void error(String message, Object? err, [StackTrace? st]) {
    log('ERROR: $message: $err');
    if (st != null) log('  ${st.toString().split('\n').take(5).join('\n  ')}');
  }

  static void _writeSync(String line) {
    if (_path == null) return;
    try {
      final f = File(_path!);
      f.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }
}
