/// アプリ全体で共有する列挙型の定義。
///
/// [OutputFormat] と [DownloadState] の 2 種類を提供する。
library;

/// ダウンロード後の出力ファイル形式。
enum OutputFormat {
  /// 音声のみの MP3 ファイル。192kbps でエンコードする。
  mp3,

  /// 映像と音声を含む MP4 ファイル。
  ///
  /// 再生互換性のため h264 (avc1) を優先して選択し、ffmpeg でマージする。
  mp4,
}

/// ダウンロード処理の現在の状態。
///
/// UI はこの値を参照してプログレスバー・ボタンの活性/非活性・
/// ステータスカードの色などを切り替える。
enum DownloadState {
  /// 待機中。何も処理していない初期状態。
  idle,

  /// yt-dlp で動画のメタ情報を取得中。
  fetching,

  /// YouTube のストリームデータをダウンロード中。
  downloading,

  /// ffmpeg で映像・音声のマージまたは MP3 変換を実行中。
  converting,

  /// 全処理が正常に完了した状態。
  done,

  /// いずれかの処理でエラーが発生した状態。
  error,
}
