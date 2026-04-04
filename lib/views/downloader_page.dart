import 'dart:io';
import 'package:flutter/material.dart';

import '../viewmodels/downloader_viewmodel.dart';
import '../models/enums.dart';
import '../l10n/app_localizations.dart';
import 'widgets/format_card.dart';
import 'widgets/video_info_card.dart';
import 'widgets/status_section.dart';
import 'widgets/log_panel.dart';

/// ダウンロード画面（View）。
///
/// [DownloaderViewModel] の状態を [ListenableBuilder] で監視し、
/// 変化があるたびに UI を再描画する。
/// ユーザー操作はすべて [DownloaderViewModel] のメソッドに委譲する。
class DownloaderPage extends StatefulWidget {
  /// コンストラクタ。
  const DownloaderPage({super.key});

  @override
  State<DownloaderPage> createState() => _DownloaderPageState();
}

class _DownloaderPageState extends State<DownloaderPage> {
  /// URL 入力フィールドのコントローラ。
  final _urlController = TextEditingController();

  /// この State が所有する ViewModel。ページのライフサイクルに合わせて破棄する。
  late final DownloaderViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DownloaderViewModel();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  /// 入力フィールドから URL を取得して前後の空白を除去するゲッター。
  String get _url => _urlController.text.trim();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        // ロケール情報を毎ビルド時に ViewModel へ注入する
        _viewModel.setL10n(AppLocalizations.of(context)!);
        return _buildScaffold(context);
      },
    );
  }

  /// [Scaffold] 全体を構築する。
  Widget _buildScaffold(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTitle(context, l10n),
                  const SizedBox(height: 8),
                  _buildFfmpegBadge(context, l10n),
                  const SizedBox(height: 32),
                  _buildUrlField(context, l10n),
                  const SizedBox(height: 10),
                  _buildFetchButton(context, l10n),
                  const SizedBox(height: 20),
                  _buildFormatSelector(l10n),
                  const SizedBox(height: 20),
                  if (_viewModel.videoInfo != null) ...[
                    VideoInfoCard(video: _viewModel.videoInfo!),
                    const SizedBox(height: 20),
                  ],
                  _buildDownloadButton(context, l10n),
                  const SizedBox(height: 16),
                  StatusSection(
                    state: _viewModel.state,
                    statusMessage: _viewModel.statusMessage,
                    progress: _viewModel.progress,
                    savedPath: _viewModel.savedPath,
                    l10n: l10n,
                  ),
                  if (_viewModel.savedPath.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildOpenFolderButton(l10n),
                  ],
                  if (_viewModel.state == DownloadState.done ||
                      _viewModel.state == DownloadState.error) ...[
                    const SizedBox(height: 8),
                    _buildResetButton(l10n),
                  ],
                  if (_viewModel.logs.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    LogPanel(logs: _viewModel.logs, l10n: l10n),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── 各ウィジェット構築メソッド ──────────────────────────────

  /// アプリタイトルを表示する行ウィジェットを返す。
  Widget _buildTitle(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.ondemand_video, color: cs.primary, size: 36),
        const SizedBox(width: 12),
        Text(
          l10n.appTitle,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// ffmpeg の検出状態を示すバッジテキストを返す。
  Widget _buildFfmpegBadge(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final label = _viewModel.ffmpegAvailable
        ? l10n.ffmpegDetected
        : l10n.ffmpegNotDetected;
    return Center(
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
    );
  }

  /// YouTube URL を入力するテキストフィールドを返す。
  Widget _buildUrlField(BuildContext context, AppLocalizations l10n) {
    return TextField(
      controller: _urlController,
      enabled: !_viewModel.isBusy,
      decoration: InputDecoration(
        labelText: l10n.urlLabel,
        hintText: l10n.urlHint,
        prefixIcon: const Icon(Icons.link),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: _urlController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: !_viewModel.isBusy
                    ? () => setState(() => _urlController.clear())
                    : null,
              )
            : null,
      ),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _viewModel.fetchInfo(_url),
    );
  }

  /// 「動画情報を取得」ボタンを返す。
  Widget _buildFetchButton(BuildContext context, AppLocalizations l10n) {
    return OutlinedButton.icon(
      onPressed: _viewModel.isBusy || _url.isEmpty
          ? null
          : () => _viewModel.fetchInfo(_url),
      icon: _viewModel.state == DownloadState.fetching
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.search),
      label: Text(l10n.fetchButton),
    );
  }

  /// MP3 / MP4 フォーマット選択カードの行を返す。
  Widget _buildFormatSelector(AppLocalizations l10n) {
    return Row(
      children: OutputFormat.values.map((f) {
        final isLast = f == OutputFormat.values.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: isLast ? 12 : 0),
            child: FormatCard(
              value: f,
              groupValue: _viewModel.format,
              enabled: !_viewModel.isBusy,
              onTap: _viewModel.setFormat,
              l10n: l10n,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 「ダウンロード」ボタンを返す。
  Widget _buildDownloadButton(BuildContext context, AppLocalizations l10n) {
    return FilledButton.icon(
      onPressed: _viewModel.isBusy
          ? null
          : () => _viewModel.startDownload(_url),
      icon: _viewModel.isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.download),
      label: Text(
        _viewModel.isBusy ? l10n.processing : l10n.downloadButton,
        style: const TextStyle(fontSize: 16),
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// 「保存先フォルダを開く」ボタンを返す。
  Widget _buildOpenFolderButton(AppLocalizations l10n) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.folder_open),
      label: Text(l10n.openFolderButton),
      onPressed: () =>
          Process.run('open', [File(_viewModel.savedPath).parent.path]),
    );
  }

  /// 「最初に戻る」ボタンを返す。
  Widget _buildResetButton(AppLocalizations l10n) {
    return OutlinedButton.icon(
      onPressed: () {
        _urlController.clear();
        _viewModel.reset();
      },
      icon: const Icon(Icons.refresh),
      label: Text(l10n.resetButton),
    );
  }
}
