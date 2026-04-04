import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../l10n/app_localizations.dart';

/// ステータスメッセージ・プログレスバー・保存先パスを表示するセクション。
///
/// [state] に応じて以下を切り替える:
/// - [DownloadState.downloading]: 進捗値付きの [LinearProgressIndicator] を表示。
/// - [DownloadState.converting]: 不確定（indeterminate）の [LinearProgressIndicator] を表示。
/// - [DownloadState.error]     : エラーカラーのステータスカードを表示。
/// - [DownloadState.done]      : プライマリカラーのステータスカードを表示。
class StatusSection extends StatelessWidget {
  /// 現在の処理状態。
  final DownloadState state;

  /// カードに表示するステータスメッセージ。空文字の場合はカード非表示。
  final String statusMessage;

  /// ダウンロード進捗（0.0〜1.0）。[DownloadState.downloading] 時に使用する。
  final double progress;

  /// 保存完了ファイルのフルパス。空文字の場合は非表示。
  final String savedPath;

  /// ローカライゼーションインスタンス。保存先パスのラベル表示に使用する。
  final AppLocalizations l10n;

  /// コンストラクタ。すべてのプロパティは必須。
  const StatusSection({
    super.key,
    required this.state,
    required this.statusMessage,
    required this.progress,
    required this.savedPath,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // プログレスバー（ダウンロード・変換中のみ表示）
        if (state == DownloadState.downloading ||
            state == DownloadState.converting) ...[
          LinearProgressIndicator(
            value: state == DownloadState.converting
                ? null
                : (progress > 0 ? progress : null),
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
        ],

        // ステータスメッセージカード
        if (statusMessage.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: switch (state) {
                DownloadState.error => cs.errorContainer,
                DownloadState.done => cs.primaryContainer,
                _ => cs.surfaceContainerHigh,
              },
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      switch (state) {
                        DownloadState.error => Icons.error_outline,
                        DownloadState.done => Icons.check_circle_outline,
                        _ => Icons.info_outline,
                      },
                      color: switch (state) {
                        DownloadState.error => cs.error,
                        DownloadState.done => cs.primary,
                        _ => cs.onSurfaceVariant,
                      },
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusMessage,
                        style: TextStyle(
                          color: state == DownloadState.error
                              ? cs.onErrorContainer
                              : cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),

                /// 保存先パスを選択可能なテキストで表示する（コピー操作を可能にする）。
                if (savedPath.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SelectableText(
                    l10n.savedPath(savedPath),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
