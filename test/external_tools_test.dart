import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_youtube_downloader/services/external_tools.dart';

void main() {
  /// 指定したパスだけが存在する世界を作る。
  bool Function(String) only(Set<String> present) => present.contains;

  group('ExternalTools.detect', () {
    test('Homebrew の固定パスから3種すべてを見つける', () {
      final t = ExternalTools.detect(
        exists: only({
          '/opt/homebrew/bin/yt-dlp',
          '/opt/homebrew/bin/ffmpeg',
          '/opt/homebrew/bin/deno',
        }),
        pathDirs: const [],
      );
      expect(t.ytDlpPath, '/opt/homebrew/bin/yt-dlp');
      expect(t.ffmpegPath, '/opt/homebrew/bin/ffmpeg');
      expect(t.jsRuntimePath, '/opt/homebrew/bin/deno');
      expect(t.isReady, isTrue);
      expect(t.missing, isEmpty);
    });

    test('Intel Mac の /usr/local/bin も探索する', () {
      final t = ExternalTools.detect(
        exists: only({'/usr/local/bin/yt-dlp'}),
        pathDirs: const [],
      );
      expect(t.ytDlpPath, '/usr/local/bin/yt-dlp');
    });

    test('固定パスに無ければ PATH のディレクトリを探索する', () {
      final t = ExternalTools.detect(
        exists: only({'/Users/me/.nvm/versions/node/v24.18.0/bin/node'}),
        pathDirs: const ['/Users/me/.nvm/versions/node/v24.18.0/bin'],
      );
      expect(t.jsRuntimePath, '/Users/me/.nvm/versions/node/v24.18.0/bin/node');
    });

    test('deno を node より優先する', () {
      final t = ExternalTools.detect(
        exists: only({
          '/opt/homebrew/bin/node',
          '/opt/homebrew/bin/deno',
        }),
        pathDirs: const [],
      );
      expect(t.jsRuntimePath, '/opt/homebrew/bin/deno');
    });

    test('何も無ければ全て null で missing に3件並ぶ', () {
      final t = ExternalTools.detect(exists: only({}), pathDirs: const []);
      expect(t.ytDlpPath, isNull);
      expect(t.ffmpegPath, isNull);
      expect(t.jsRuntimePath, isNull);
      expect(t.isReady, isFalse);
      expect(t.missing, [
        MissingTool.ytDlp,
        MissingTool.ffmpeg,
        MissingTool.jsRuntime,
      ]);
    });

    test('一部だけ欠けている場合は欠けているものだけを返す', () {
      final t = ExternalTools.detect(
        exists: only({
          '/opt/homebrew/bin/yt-dlp',
          '/opt/homebrew/bin/ffmpeg',
        }),
        pathDirs: const [],
      );
      expect(t.isReady, isFalse);
      expect(t.missing, [MissingTool.jsRuntime]);
    });
  });

  group('installCommand', () {
    test('各ツールの導入コマンドを返す', () {
      expect(installCommand(MissingTool.ytDlp), 'brew install yt-dlp');
      expect(installCommand(MissingTool.ffmpeg), 'brew install ffmpeg');
      expect(installCommand(MissingTool.jsRuntime), 'brew install deno');
    });
  });
}
