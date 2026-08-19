/// 動画のメタ情報を UI 向けに保持するモデル。
///
/// ViewModel が [VideoInfo.fromYtDlpJson] で yt-dlp の JSON から変換して保持し、
/// View はこのクラスを通じてタイトル・投稿者・再生時間を参照する。
/// yt-dlp の JSON 構造を View 層に露出させないための境界として機能する。
class VideoInfo {
  /// YouTube 動画の ID 文字列（例: `"dQw4w9WgXcQ"`）。
  final String id;

  /// 動画のタイトル。
  final String title;

  /// 動画の投稿者（チャンネル名）。
  final String author;

  /// 動画の再生時間。取得できない場合は `null`。
  final Duration? duration;

  /// すべてのフィールドを指定するデフォルトコンストラクタ。
  const VideoInfo({
    required this.id,
    required this.title,
    required this.author,
    this.duration,
  });

  /// yt-dlp の `--dump-single-json` 出力からインスタンスを生成する。
  ///
  /// `duration` は秒数で、動画によっては小数や欠損があるため丸めと既定値を入れる。
  /// 投稿者は `uploader` が無い動画があるため `channel` にフォールバックする。
  factory VideoInfo.fromYtDlpJson(Map<String, dynamic> json) {
    final seconds = json['duration'];
    return VideoInfo(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['uploader'] as String? ?? json['channel'] as String? ?? '',
      duration: seconds is num ? Duration(seconds: seconds.round()) : null,
    );
  }

  /// 再生時間を `"M:SS"` 形式の文字列で返すゲッター。
  ///
  /// [duration] が `null`（取得不可）の場合は `"--:--"` を返す。
  /// 例: 3分7秒 → `"3:07"`
  String get durationLabel {
    final d = duration;
    if (d == null) return '--:--';
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
