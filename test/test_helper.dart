import 'package:flutter/services.dart';

///テスト実行時のフォント読み込み処理
Future<void> loadFonts() async {
  // MaterialIcons
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  // notoSansJp
  final notoSansJp = FontLoader('NotoSansJP')
    ..addFont(rootBundle.load('assets/fonts/NotoSansJP/NotoSansJP-Regular.otf'))
    ..addFont(rootBundle.load('assets/fonts/NotoSansJP/NotoSansJP-Bold.otf'));
  // Roboto
  final roboto = FontLoader('Roboto')
    ..addFont(rootBundle.load('assets/fonts/Roboto/Roboto-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Roboto/Roboto-Bold.ttf'));

  await materialIcons.load();
  await notoSansJp.load();
  await roboto.load();
}
