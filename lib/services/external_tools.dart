import 'dart:io';

/// アプリが動作に必要とする外部コマンドの種類。
enum MissingTool {
  /// ダウンロード本体。
  ytDlp,

  /// MP3 変換・映像音声マージに使う。
  ffmpeg,

  /// yt-dlp が YouTube の署名チャレンジを解くために必要な JavaScript ランタイム。
  ///
  /// これが無いと `n challenge solving failed` となりフォーマットが 0 件になる。
  jsRuntime,
}

/// [tool] を導入するためのコマンド文字列を返す。
String installCommand(MissingTool tool) => switch (tool) {
      MissingTool.ytDlp => 'brew install yt-dlp',
      MissingTool.ffmpeg => 'brew install ffmpeg',
      MissingTool.jsRuntime => 'brew install deno',
    };

/// 検出済みの外部コマンドのパスをまとめて保持する。
///
/// 検出は [File.existsSync] のみで行い、`Process.run` は使わない。
/// macOS 26 以降、Finder から起動したアプリが起動直後に `Process.run` を
/// 呼ぶとプロセスが SIGKILL される問題があるため。
class ExternalTools {
  /// yt-dlp 実行ファイルのフルパス。未検出なら `null`。
  final String? ytDlpPath;

  /// ffmpeg 実行ファイルのフルパス。未検出なら `null`。
  final String? ffmpegPath;

  /// JavaScript ランタイム（deno / node / bun）のフルパス。未検出なら `null`。
  final String? jsRuntimePath;

  const ExternalTools({
    this.ytDlpPath,
    this.ffmpegPath,
    this.jsRuntimePath,
  });

  /// 3種すべてが揃っていれば `true`。
  bool get isReady =>
      ytDlpPath != null && ffmpegPath != null && jsRuntimePath != null;

  /// 不足しているツールを [MissingTool] の宣言順で返す。
  List<MissingTool> get missing => [
        if (ytDlpPath == null) MissingTool.ytDlp,
        if (ffmpegPath == null) MissingTool.ffmpeg,
        if (jsRuntimePath == null) MissingTool.jsRuntime,
      ];

  /// 固定パス候補と `PATH` のディレクトリを順に探索して各ツールを検出する。
  ///
  /// 固定パスを先に見るのは、Finder から起動した場合 `PATH` が
  /// `/usr/bin:/bin:/usr/sbin:/sbin` だけになり Homebrew を見つけられないため。
  ///
  /// - [exists]   : パスの存在判定。省略時は [File.existsSync]。テスト用の差し替え口。
  /// - [pathDirs] : `PATH` 相当のディレクトリ一覧。省略時は環境変数から読む。
  static ExternalTools detect({
    bool Function(String path)? exists,
    List<String>? pathDirs,
  }) {
    final check = exists ?? (p) => File(p).existsSync();
    final dirs = pathDirs ?? _envPathDirs();

    String? find(List<String> names) {
      for (final name in names) {
        for (final dir in [..._fixedPrefixes, ...dirs]) {
          final path = '$dir/$name';
          if (check(path)) return path;
        }
      }
      return null;
    }

    return ExternalTools(
      ytDlpPath: find(_exeNames('yt-dlp')),
      ffmpegPath: find(_exeNames('ffmpeg')),
      // deno を最優先にする。yt-dlp の署名解読で最も安定して動く。
      jsRuntimePath: find([
        ..._exeNames('deno'),
        ..._exeNames('node'),
        ..._exeNames('bun'),
      ]),
    );
  }

  /// Windows では `.exe` 付きも候補にする。
  static List<String> _exeNames(String base) =>
      Platform.isWindows ? ['$base.exe', base] : [base];

  static List<String> _envPathDirs() =>
      (Platform.environment['PATH'] ?? '')
          .split(Platform.isWindows ? ';' : ':')
          .where((e) => e.isNotEmpty)
          .toList();

  /// Homebrew / MacPorts / システム標準の実行ファイル置き場。
  static const _fixedPrefixes = [
    '/opt/homebrew/bin',
    '/usr/local/bin',
    '/opt/local/bin',
    '/usr/bin',
  ];
}
