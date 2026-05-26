# セキュリティ・コード解析

## MobSF
- [github](https://github.com/MobSF/Mobile-Security-Framework-MobSF)
```sh
docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf:latest
```

## 未使用ファイルの検出
[Flutter: Find Unused Dart Files & Assets](https://medium.com/@Saurabh7973/easiest-way-to-reduce-app-size-in-flutter-apps-cb3da18a089a)

以下のように出力をしてくれる。
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
