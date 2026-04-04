import 'package:flutter/material.dart';
import '../../models/video_info.dart';

/// 取得済みの YouTube 動画情報を表示するカード。
///
/// サムネイルの代わりにアイコンを表示し、タイトル・投稿者・再生時間を
/// 2 行のテキストで並べる。[VideoInfo.durationLabel] で整形された時間を使用する。
class VideoInfoCard extends StatelessWidget {
  /// 表示する動画情報。
  final VideoInfo video;

  /// コンストラクタ。[video] は必須。
  const VideoInfoCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          /// 動画のプレースホルダーアイコン。
          Icon(Icons.play_circle_outline, color: cs.primary, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 動画タイトル。最大 2 行で省略表示する。
                Text(
                  video.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                /// 投稿者名と再生時間を "·" 区切りで表示する。
                Text(
                  '${video.author}  ·  ${video.durationLabel}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
