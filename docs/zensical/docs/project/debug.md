# コマンドリファレンス

## Git操作
```sh
# modify remote git branch
./rename_branch.sh {before} {after}
```

## コード品質管理

#### Linting
```sh
# Fix package import issues
dart fix --apply --code=always_use_package_imports
# Fix directive ordering issues
dart fix --apply --code=directives_ordering
# Fix missing dependency issues
dart fix --apply --code=missing_dependency
# Format all Dart files in the project
dart format .
```

#### 解析
```sh
flutter analyze --no-fatal-infos # info レベルのメッセージでビルドを失敗させない
flutter analyze --no-fatal-warnings # warning レベルのメッセージでビルドを失敗させない
```

#### analysis_options.yamlのルール
- [公式のルール（ドキュメント）](https://dart.dev/tools/linter-rules)
- [公式のルール（github yamlファイル）](https://github.com/flutter/flutter/blob/master/analysis_options.yaml)

## ビルド・実行

#### コード生成
`lib/main/env.dart`から`lib/main/env.g.dart`などのファイルを生成する際に実行。
```sh
dart run build_runner build
```

#### アプリ起動
[プロファイルモード](https://docs.flutter.dev/perf/ui-performance)はパフォーマンス計測時に使用。
```sh
flutter run --release --target-platform android-arm64
flutter run --profile
```

#### 起動パフォーマンス測定
起動パフォーマンスの測定には、プロファイルモードを使用。
build/start_up_info.jsonの「timeToFirstFrameMicros」を確認します。Firebase Performance Monitoringによる本番環境での継続的な監視も重要です。
```sh
flutter run --profile --trace-startup
```

#### APKファイル作成
```sh
.\gradlew --stop
flutter build apk --release
flutter build apk --split-per-abi --obfuscate --split-debug-info=build/app/outputs/logs --tree-shake-icons
```

##### adbコマンドでインストール・アンインストール
```shell
# アプリ全体の情報を確認
adb shell dumpsys package com.enoconan.testingappv2 > app_info.txt
# アンインストール
adb uninstall com.enoconan.testingappv2
# アプリインストール
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# 既存アプリを保持したまま更新
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# デバイスのアプリリンクの状態をリセット
adb shell pm set-app-links --package com.enoconan.testingappv2 0 all
# システムに再検証を強制する
adb shell pm verify-app-links --re-verify com.enoconan.testingappv2
# 検証結果を確認
adb shell pm get-app-links com.enoconan.testingappv2

[Android ABI](https://developer.android.com/ndk/guides/abis?hl=ja)
> App Distributionにアップロードするapkファイルのサイズを小さくしたいことから始まった。ABI別のapkファイル作成については、冒頭のコマンド部分に記載の通り。

#### Gradleの警告解消
[apkビルド時の以下警告を解消](https://docs.gradle.org/current/userguide/build_environment.html)
> Caught exception: Already watching path: /home/runner/work/flutter-testing-app-google/flutter-testing-app-google/android

`android/gradle.properties`に以下を追加
```text
org.gradle.vfs.watch=false
org.gradle.unsafe.watch-fs=false
```

#### 特定フォルダをビルド対象外に
[参考](https://stackoverflow.com/questions/68534482/how-to-exclude-a-file-while-building-a-apk-in-flutter)
```gradle
sourceSets {
    main {
        // ビルド時に除外するリソース
        resources {
            excludes += ['edge-functions/**']
        }
    }
}
```
