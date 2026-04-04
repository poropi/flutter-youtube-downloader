/// 処理ログの 1 行分を表すデータクラス。
///
/// [DownloaderViewModel] が内部処理の各ステップで [LogEntry] を生成し、
/// [LogPanel] ウィジェットがタイムスタンプ付きで表示する。
class LogEntry {
  /// ログに表示するメッセージ文字列。
  final String message;

  /// このエントリが生成された日時。[LogPanel] で "HH:MM:SS" 形式に整形される。
  final DateTime time;

  /// エラーレベルのログかどうか。
  ///
  /// `true` の場合、[LogPanel] はテキストをエラーカラーで描画する。
  final bool isError;

  /// [message] を受け取ってログエントリを生成する。
  ///
  /// [time] はコンストラクタ呼び出し時点の [DateTime.now] で自動設定される。
  ///
  /// - [message] : 表示するログ文字列。
  /// - [isError] : エラーレベルの場合は `true`（デフォルト: `false`）。
  LogEntry(this.message, {this.isError = false}) : time = DateTime.now();
}
