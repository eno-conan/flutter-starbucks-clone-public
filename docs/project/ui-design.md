# UI・デザイン

## アプリアイコン設定

### splash画像の設定
- [参考記事](https://medium.com/@hemantkumarceo001/day-38-how-to-create-a-flutter-native-splash-screen-in-your-app-b6cd50db297e)
- `flutter_native_splash.yaml`に記載の通り、画像パスと色を設定
- コマンド実行
```bash
  dart run flutter_native_splash:create
```

### flutter_launcher_iconsの設定
- [参考記事](https://zenn.dev/hott3/articles/flutter-launcher-image)
- [Notion](https://www.notion.so/flutter_native_splash-flutter_launcher_icons-1748580db195807aaa2ac3db0eac0828)
- `flutter_native_splash.yaml`に記載の通り、画像パスと色を設定
- コマンド実行
```bash
  dart run flutter_launcher_icons
```

## アイコン・画像リソース
- [Material3](https://fonts.google.com/icons)
- [アイコンをダウンロード](https://icons8.jp/icons)
- [アイコンをダウンロード2](https://icooon-mono.com/)
- [カラーコード](https://www.colordic.org/)
- [画像サイズ変更](https://www.iloveimg.com/ja/resize-image/resize-png#resize-options,pixels)

## ステータスバーの色設定
[参考](https://pc.gajeroll.com/programming/flutter/set-status-bar-color)
```dart
@override
Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
        statusBarColor: Colors.blue, // 色を指定
    ),
    );
    return Container();
}
```
