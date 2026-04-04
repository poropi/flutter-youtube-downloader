/// アプリ全体で共有する列挙型の定義。
///
/// [OutputFormat] と [DownloadState] の 2 種類を提供する。
library;

/// ダウンロード後の出力ファイル形式。
enum OutputFormat {
  /// 音声のみの MP3 ファイル。
  ///
  /// ffmpeg が利用可能な場合は 192kbps・44.1kHz でエンコードする。
  /// ffmpeg が無い場合は元の音声コンテナ（.m4a など）のまま保存する。
  mp3,

  /// 映像と音声を含む MP4 ファイル。
  ///
  /// ffmpeg が利用可能な場合は最高画質の映像と最高ビットレートの音声を
  /// 別々に取得して ffmpeg でマージする。
  /// ffmpeg が無い場合は muxed ストリーム（最大 360p）を直接保存する。
  mp4,
}

/// ダウンロード処理の現在の状態。
///
/// UI はこの値を参照してプログレスバー・ボタンの活性/非活性・
/// ステータスカードの色などを切り替える。
enum DownloadState {
  /// 待機中。何も処理していない初期状態。
  idle,

  /// youtube_explode_dart で動画のメタ情報を取得中。
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
