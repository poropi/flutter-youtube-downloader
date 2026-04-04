import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../l10n/app_localizations.dart';

/// MP3 / MP4 を選択するフォーマット選択カード。
///
/// 選択状態に応じて [AnimatedContainer] でボーダーと背景色をアニメーション変化させる。
/// [groupValue] と [value] が一致しているカードが選択済み状態として描画される。
class FormatCard extends StatelessWidget {
  /// このカードが表すフォーマット値。
  final OutputFormat value;

  /// 現在選択されているフォーマット。[value] と一致すれば選択済み状態になる。
  final OutputFormat groupValue;

  /// タップを受け付けるかどうか。`false` の場合はタップ無効（処理中など）。
  final bool enabled;

  /// カードがタップされたときに呼び出されるコールバック。[value] を引数として渡す。
  final ValueChanged<OutputFormat> onTap;

  /// ローカライゼーションインスタンス。サブタイトルの表示に使用する。
  final AppLocalizations l10n;

  /// コンストラクタ。すべてのプロパティは必須。
  const FormatCard({
    super.key,
    required this.value,
    required this.groupValue,
    required this.enabled,
    required this.onTap,
    required this.l10n,
  });

  /// このカードが選択済みかどうか。
  bool get _selected => value == groupValue;

  /// フォーマットに対応するアイコン。MP3 は音符、MP4 はビデオカメラ。
  IconData get _icon =>
      value == OutputFormat.mp3 ? Icons.music_note : Icons.videocam;

  /// フォーマット名のラベル文字列（"MP3" または "MP4"）。
  String get _label => value == OutputFormat.mp3 ? 'MP3' : 'MP4';

  /// フォーマットの説明文字列（ロケールに応じて切り替わる）。
  String _subtitle() =>
      value == OutputFormat.mp3 ? l10n.formatMp3Subtitle : l10n.formatMp4Subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: enabled ? () => onTap(value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: _selected ? cs.primaryContainer : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selected ? cs.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, color: _selected ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selected ? cs.primary : cs.onSurface,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _subtitle(),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
