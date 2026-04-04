import 'package:flutter/material.dart';
import '../../models/log_entry.dart';

/// タイムスタンプ付きの処理ログを表示するパネルウィジェット。
///
/// [DownloaderViewModel] が生成した [LogEntry] リストを受け取り、
/// 各エントリを "HH:MM:SS  メッセージ" の形式で等幅フォントで表示する。
/// エラーレベルのエントリはエラーカラーで強調表示される。
/// メッセージは [SelectableText] なのでコピー操作が可能。
class LogPanel extends StatelessWidget {
  /// 表示するログエントリのリスト。
  final List<LogEntry> logs;

  /// コンストラクタ。[logs] は必須。
  const LogPanel({super.key, required this.logs});

  /// [DateTime] を `"HH:MM:SS"` 形式の文字列にフォーマットする。
  ///
  /// - [t] : フォーマット対象の日時。
  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// パネルのヘッダー行（ターミナルアイコン + "処理ログ" ラベル）。
          Row(
            children: [
              Icon(Icons.terminal, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '処理ログ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          /// 各ログエントリを "タイムスタンプ + メッセージ" の行として表示する。
          ...logs.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// タイムスタンプ（等幅フォント、サブテキストカラー）。
                  Text(
                    _formatTime(e.time),
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),

                  /// ログメッセージ（選択可能、エラーは赤色）。
                  Expanded(
                    child: SelectableText(
                      e.message,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: e.isError ? cs.error : cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
