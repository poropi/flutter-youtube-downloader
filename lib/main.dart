/// アプリケーションのエントリポイント。
///
/// [runApp] を呼び出して Flutter フレームワークにアプリを登録する。
library;

import 'package:flutter/material.dart';
import 'views/downloader_page.dart';

/// アプリを起動する。
///
/// Flutter エンジンが初期化されたあと [MyApp] ウィジェットをルートに設定する。
void main() {
  runApp(const MyApp());
}

/// アプリのルートウィジェット。
///
/// [MaterialApp] を生成し、テーマ・初期画面を設定する。
/// Material Design 3 / ダークテーマをベーステーマとして使用する。
class MyApp extends StatelessWidget {
  /// コンストラクタ。
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /// アプリのタイトル（OSのタスクスイッチャーなどに表示される）。
      title: 'YouTube Downloader',

      /// デバッグモードのバナーを非表示にする。
      debugShowCheckedModeBanner: false,

      /// YouTube の赤をシードカラーとしたダークテーマ。
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF0000),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      /// 起動直後に表示する画面。
      home: const DownloaderPage(),
    );
  }
}
