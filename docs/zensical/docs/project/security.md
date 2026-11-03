# セキュリティ・コード解析

## MobSF

- [github](https://github.com/MobSF/Mobile-Security-Framework-MobSF)

```sh
docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf:latest
```

## セキュリティ対策

- **SSL Certificate Pinning**: 中間者攻撃を防止する。
- **暗号化ストレージ**: 機密データを安全に保存する。
- **API認証**: JWT トークンベース認証。
- **入力バリデーション**: SQL インジェクションなどを防止する。
- **OWASP Mobile Top 10** 準拠。
- **MobSF セキュリティスキャン**: 定期実行する。

## 未使用ファイルの検出

- 参考: [Flutter: Find Unused Dart Files & Assets](https://medium.com/@Saurabh7973/easiest-way-to-reduce-app-size-in-flutter-apps-cb3da18a089a)
- 次のように、出力してくれる。

??? example "出力例（未使用のアセット・依存・Dart ファイル）"
    ```text
    ---------------------------------
    2 unreferenced assets
    ---------------------------------
    1. c:\Users\Administrator\flutter\testingapp\assets\icons\app\splash-logo.png
    2. c:\Users\Administrator\flutter\testingapp\assets\icons\app\ic_launcher_foreground.png

    ---------------------------------
    2 unreferenced dependencies
    ---------------------------------
    1. flutter_native_splash
    2. flutter_launcher_icons

    ---------------------------------
    2 unreferenced dart files
    ---------------------------------
    1. c:\Users\Administrator\flutter\testingapp\lib\screens\qr\scan_qr.dart
    ```
