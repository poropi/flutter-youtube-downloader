import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_youtube_downloader/models/enums.dart';
import 'package:flutter_youtube_downloader/models/video_info.dart';
import 'package:flutter_youtube_downloader/services/ytdlp_service.dart';

void main() {
  group('parseProgressLine', () {
    test('ダウンロード中の行から受信バイト数と合計を取り出す', () {
      final p = parseProgressLine('YTDLP_PROGRESS|downloading|1024|54495005');
      expect(p, isNotNull);
      expect(p!.status, 'downloading');
      expect(p.downloadedBytes, 1024);
      expect(p.totalBytes, 54495005);
      expect(p.fraction, closeTo(1024 / 54495005, 1e-9));
    });

    test('完了行を認識する', () {
      final p = parseProgressLine('YTDLP_PROGRESS|finished|3433755|3433755');
      expect(p!.status, 'finished');
      expect(p.fraction, 1.0);
    });

    test('合計が NA のときは fraction が null になる', () {
      final p = parseProgressLine('YTDLP_PROGRESS|downloading|2048|NA');
      expect(p!.totalBytes, isNull);
      expect(p.fraction, isNull);
    });

    test('進捗行以外は null を返す', () {
      expect(parseProgressLine('[download] Destination: foo.webm'), isNull);
      expect(parseProgressLine(''), isNull);
      expect(parseProgressLine('YTDLP_PROGRESS|downloading|1024'), isNull);
    });
  });

  group('parseSavedPath', () {
    test('保存先パス行からパスを取り出す', () {
      expect(
        parseSavedPath('YTDLP_PATH|/Users/me/Downloads/My Video.mp3'),
        '/Users/me/Downloads/My Video.mp3',
      );
    });

    test('パスに | が含まれても末尾まで返す', () {
      expect(
        parseSavedPath('YTDLP_PATH|/tmp/a|b.mp4'),
        '/tmp/a|b.mp4',
      );
    });

    test('該当しない行は null を返す', () {
      expect(parseSavedPath('[ExtractAudio] Destination: x.mp3'), isNull);
    });
  });

  group('parseStage', () {
    test('ダウンロード開始を検出する', () {
      expect(parseStage('[download] Destination: /tmp/a.webm'),
          YtDlpStage.downloading);
    });

    test('MP3 変換を検出する', () {
      expect(parseStage('[ExtractAudio] Destination: /tmp/a.mp3'),
          YtDlpStage.converting);
    });

    test('映像音声マージを検出する', () {
      expect(parseStage('[Merger] Merging formats into "/tmp/a.mp4"'),
          YtDlpStage.merging);
    });

    test('無関係な行は null を返す', () {
      expect(parseStage('[youtube] Extracting URL: https://...'), isNull);
    });
  });

  group('extractErrorMessage', () {
    test('ERROR: 行の本文を返す', () {
      final msg = extractErrorMessage([
        '[youtube] Extracting URL: https://x',
        'WARNING: something minor',
        'ERROR: unable to download video data: HTTP Error 403: Forbidden',
      ]);
      expect(msg, 'unable to download video data: HTTP Error 403: Forbidden');
    });

    test('ERROR: が複数あれば最初の1件を返す', () {
      final msg = extractErrorMessage([
        'ERROR: first problem',
        'ERROR: second problem',
      ]);
      expect(msg, 'first problem');
    });

    test('ERROR: が無ければ null を返す', () {
      expect(extractErrorMessage(['[download] 100%']), isNull);
    });
  });

  group('buildDownloadArgs', () {
    List<String> args({
      OutputFormat format = OutputFormat.mp3,
      bool useEmbeddedClient = true,
    }) =>
        buildDownloadArgs(
          url: 'https://www.youtube.com/watch?v=abc',
          format: format,
          outputDir: '/Users/me/Downloads',
          ffmpegPath: '/opt/homebrew/bin/ffmpeg',
          useEmbeddedClient: useEmbeddedClient,
        );

    test('web_embedded クライアントを明示指定する', () {
      final a = args();
      final i = a.indexOf('--extractor-args');
      expect(i, isNot(-1));
      expect(a[i + 1], 'youtube:player_client=web_embedded');
    });

    test('フォールバック時はクライアント指定を外す', () {
      expect(args(useEmbeddedClient: false), isNot(contains('--extractor-args')));
    });

    test('進捗テンプレートと保存先パス出力を有効にする', () {
      final a = args();
      expect(a, contains('--newline'));
      expect(a, contains('--no-quiet'));
      final p = a.indexOf('--progress-template');
      expect(a[p + 1], startsWith('YTDLP_PROGRESS|'));
      final pr = a.indexOf('--print');
      expect(a[pr + 1], 'after_move:YTDLP_PATH|%(filepath)s');
    });

    test('検出した ffmpeg のパスを渡す', () {
      final a = args();
      final i = a.indexOf('--ffmpeg-location');
      expect(a[i + 1], '/opt/homebrew/bin/ffmpeg');
    });

    test('MP3 は 192kbps 指定で音声抽出する', () {
      final a = args(format: OutputFormat.mp3);
      expect(a, containsAllInOrder(['--audio-format', 'mp3']));
      expect(a, containsAllInOrder(['--audio-quality', '192K']));
      expect(a, contains('-x'));
    });

    test('MP4 は h264 を優先して mp4 にマージする', () {
      final a = args(format: OutputFormat.mp4);
      final i = a.indexOf('-f');
      expect(a[i + 1], startsWith('bv*[vcodec^=avc1][ext=mp4]+ba[ext=m4a]/'));
      expect(a, containsAllInOrder(['--merge-output-format', 'mp4']));
      expect(a, isNot(contains('-x')));
    });

    test('出力テンプレートに保存先ディレクトリを含める', () {
      final a = args();
      final i = a.indexOf('-o');
      expect(a[i + 1], '/Users/me/Downloads/%(title).80B.%(ext)s');
    });

    test('URL は最後の引数にする', () {
      expect(args().last, 'https://www.youtube.com/watch?v=abc');
    });
  });

  group('buildInfoArgs', () {
    test('JSON 1件だけを出力させる', () {
      final a = buildInfoArgs('https://youtu.be/abc', useEmbeddedClient: true);
      expect(a, contains('--dump-single-json'));
      expect(a, contains('--no-playlist'));
      expect(a.last, 'https://youtu.be/abc');
    });
  });

  group('VideoInfo.fromYtDlpJson', () {
    test('yt-dlp の JSON からタイトル・投稿者・長さを取り出す', () {
      final v = VideoInfo.fromYtDlpJson({
        'id': 'dQw4w9WgXcQ',
        'title': 'Never Gonna Give You Up',
        'uploader': 'Rick Astley',
        'duration': 213,
      });
      expect(v.id, 'dQw4w9WgXcQ');
      expect(v.title, 'Never Gonna Give You Up');
      expect(v.author, 'Rick Astley');
      expect(v.duration, const Duration(seconds: 213));
      expect(v.durationLabel, '3:33');
    });

    test('duration が無い場合は null になり --:-- を返す', () {
      final v = VideoInfo.fromYtDlpJson({
        'id': 'x',
        'title': 't',
        'uploader': 'u',
      });
      expect(v.duration, isNull);
      expect(v.durationLabel, '--:--');
    });

    test('duration が小数でも秒に丸めて扱える', () {
      final v = VideoInfo.fromYtDlpJson({
        'id': 'x',
        'title': 't',
        'uploader': 'u',
        'duration': 213.4,
      });
      expect(v.duration, const Duration(seconds: 213));
    });

    test('uploader が無い場合は channel を使う', () {
      final v = VideoInfo.fromYtDlpJson({
        'id': 'x',
        'title': 't',
        'channel': 'Ch',
      });
      expect(v.author, 'Ch');
    });
  });
}
