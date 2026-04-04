import 'dart:io';
import 'package:flutter/material.dart';

import '../viewmodels/downloader_viewmodel.dart';
import '../models/enums.dart';
import 'widgets/format_card.dart';
import 'widgets/video_info_card.dart';
import 'widgets/status_section.dart';
import 'widgets/log_panel.dart';

/// ダウンロード画面（View）。
///
/// [DownloaderViewModel] の状態を [ListenableBuilder] で監視し、
/// 変化があるたびに UI を再描画する。
/// ユーザー操作はすべて [DownloaderViewModel] のメソッドに委譲する。
///
/// ## レイアウト
/// - タイトル / ffmpeg 検出バッジ
/// - URL 入力フィールド / 動画情報取得ボタン
/// - 出力フォーマット選択カード（MP3 / MP4）
/// - 取得済み動画情報カード（[VideoInfoCard]）
/// - ダウンロードボタン
/// - ステータスセクション（[StatusSection]）
/// - 保存先フォルダを開くボタン / リセットボタン
/// - 処理ログパネル（[LogPanel]）
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
    // ListenableBuilder: ViewModel が notifyListeners() を呼ぶたびに
    // builder 内だけ再ビルドされる（ページ全体を StatefulWidget にする必要がない）
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  /// [Scaffold] 全体を構築する。
  Widget _buildScaffold(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                  _buildTitle(context),
                  const SizedBox(height: 8),
                  _buildFfmpegBadge(context),
                  const SizedBox(height: 32),
                  _buildUrlField(context),
                  const SizedBox(height: 10),
                  _buildFetchButton(context),
                  const SizedBox(height: 20),
                  _buildFormatSelector(),
                  const SizedBox(height: 20),
                  if (_viewModel.videoInfo != null) ...[
                    VideoInfoCard(video: _viewModel.videoInfo!),
                    const SizedBox(height: 20),
                  ],
                  _buildDownloadButton(context),
                  const SizedBox(height: 16),
                  StatusSection(
                    state: _viewModel.state,
                    statusMessage: _viewModel.statusMessage,
                    progress: _viewModel.progress,
                    savedPath: _viewModel.savedPath,
                  ),
                  if (_viewModel.savedPath.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildOpenFolderButton(),
                  ],
                  if (_viewModel.state == DownloadState.done ||
                      _viewModel.state == DownloadState.error) ...[
                    const SizedBox(height: 8),
                    _buildResetButton(),
                  ],
                  if (_viewModel.logs.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    LogPanel(logs: _viewModel.logs),
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
  Widget _buildTitle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.ondemand_video, color: cs.primary, size: 36),
        const SizedBox(width: 12),
        Text(
          'YouTube Downloader',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// ffmpeg の検出状態を示すバッジテキストを返す。
  ///
  /// ffmpeg が検出済みの場合は高画質対応を、未検出の場合は制限を案内する。
  Widget _buildFfmpegBadge(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = _viewModel.ffmpegAvailable
        ? 'ffmpeg 検出済み  ·  高画質 MP4 / MP3 変換 対応'
        : 'ffmpeg 未検出  ·  MP4 は最大 360p / 音声は .m4a 保存';
    return Center(
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
    );
  }

  /// YouTube URL を入力するテキストフィールドを返す。
  ///
  /// 入力があるとクリアボタンが表示され、Enter キーで動画情報取得を実行する。
  Widget _buildUrlField(BuildContext context) {
    return TextField(
      controller: _urlController,
      enabled: !_viewModel.isBusy,
      decoration: InputDecoration(
        labelText: 'YouTube URL',
        hintText: 'https://www.youtube.com/watch?v=...',
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
      onChanged: (_) => setState(() {}), // suffixIcon の表示更新のため
      onSubmitted: (_) => _viewModel.fetchInfo(_url),
    );
  }

  /// 「動画情報を取得」ボタンを返す。
  ///
  /// 取得中はスピナーアイコンを表示し、ボタンを無効化する。
  Widget _buildFetchButton(BuildContext context) {
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
      label: const Text('動画情報を取得'),
    );
  }

  /// MP3 / MP4 フォーマット選択カードの行を返す。
  Widget _buildFormatSelector() {
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
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 「ダウンロード」ボタンを返す。
  ///
  /// 処理中はスピナーを表示してボタンを無効化する。
  Widget _buildDownloadButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: _viewModel.isBusy
          ? null
          : () => _viewModel.startDownload(_url),
      icon: _viewModel.isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.download),
      label: Text(
        _viewModel.isBusy ? '処理中...' : 'ダウンロード',
        style: const TextStyle(fontSize: 16),
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// 「保存先フォルダを開く」ボタンを返す。
  ///
  /// macOS の `open` コマンドで [savedPath] の親ディレクトリを Finder で開く。
  Widget _buildOpenFolderButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.folder_open),
      label: const Text('保存先フォルダを開く'),
      onPressed: () =>
          Process.run('open', [File(_viewModel.savedPath).parent.path]),
    );
  }

  /// 「最初に戻る」ボタンを返す。
  ///
  /// URL フィールドをクリアし、[DownloaderViewModel.reset] で状態を初期化する。
  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: () {
        _urlController.clear();
        _viewModel.reset();
      },
      icon: const Icon(Icons.refresh),
      label: const Text('最初に戻る'),
    );
  }
}
