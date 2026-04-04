import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// youtube_explode_dart の [Video] オブジェクトを UI 向けに薄くラップしたモデル。
///
/// ViewModel が [VideoInfo.fromVideo] で変換して保持し、View はこのクラスを通じて
/// タイトル・投稿者・再生時間を参照する。
/// ライブラリ固有の型を View 層に露出させないための境界として機能する。
class VideoInfo {
  /// YouTube 動画の ID 文字列（例: `"dQw4w9WgXcQ"`）。
  ///
  /// [DownloaderViewModel] がストリームマニフェストを取得する際に
  /// `yt.videos.streams.getManifest(id)` の引数として使用する。
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

  /// youtube_explode_dart の [Video] からインスタンスを生成するファクトリ。
  ///
  /// `video.id.value` を [id] に格納することで、ライブラリの [VideoId] 型を
  /// この層より上に持ち込まないようにしている。
  factory VideoInfo.fromVideo(Video video) => VideoInfo(
        id: video.id.value,
        title: video.title,
        author: video.author,
        duration: video.duration,
      );

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
