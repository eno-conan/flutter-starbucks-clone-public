# コマンドリファレンス

## Git操作

```sh
# modify remote git branch
./rename_branch.sh {before} {after}
```

## コード品質管理

### Linting

```sh
# Fix relative import issues (lib/ 内は相対 import)
dart fix --apply --code=prefer_relative_imports
# Fix directive ordering issues
dart fix --apply --code=directives_ordering
# Fix missing dependency issues
dart fix --apply --code=missing_dependency
# Format all Dart files in the project
dart format .
```

### 解析

```sh
flutter analyze --no-fatal-infos # info レベルのメッセージでビルドを失敗させない
flutter analyze --no-fatal-warnings # warning レベルのメッセージでビルドを失敗させない
```

### analysis_options.yamlのルール

- [公式のルール（ドキュメント）](https://dart.dev/tools/linter-rules)
- [公式のルール（github yamlファイル）](https://github.com/flutter/flutter/blob/master/analysis_options.yaml)

## ビルド・実行

### コード生成

- `lib/main/env.dart` から `lib/main/env.g.dart` などのファイルを生成する際に実行する。

```sh
dart run build_runner build
```

### アプリ起動

- [プロファイルモード](https://docs.flutter.dev/perf/ui-performance)は、パフォーマンス計測時に使う。

```sh
flutter run --release --target-platform android-arm64
flutter run --profile
```

### 起動パフォーマンス測定

- 起動パフォーマンスの測定には、プロファイルモードを使う。
- `build/start_up_info.json` の `timeToFirstFrameMicros` を確認する。
- Firebase Performance Monitoring による、本番環境での継続的な監視も重要。

```sh
flutter run --profile --trace-startup
```

### APKファイル作成

```sh
.\gradlew --stop
flutter build apk --release
flutter build apk --split-per-abi --obfuscate --split-debug-info=build/app/outputs/logs --tree-shake-icons
```

!!! note "ABI 別の APK を作る理由"
    - App Distribution にアップロードする APK ファイルのサイズを、小さくしたいことから始まった。
    - ABI 別の APK ファイル作成は、冒頭のコマンド部分に記載のとおり。
    - 参考: [Android ABI](https://developer.android.com/ndk/guides/abis?hl=ja)

#### adbコマンドでインストール・アンインストール

??? example "adb コマンド（14 行）"
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
    ```

### Gradleの警告解消

- [apk ビルド時の次の警告を解消](https://docs.gradle.org/current/userguide/build_environment.html)する。

```text
Caught exception: Already watching path: /home/runner/work/flutter-testing-app-google/flutter-testing-app-google/android
```

- `android/gradle.properties` に、次を追加する。

```text
org.gradle.vfs.watch=false
org.gradle.unsafe.watch-fs=false
```

### 特定フォルダをビルド対象外に

- 参考: <https://stackoverflow.com/questions/68534482/how-to-exclude-a-file-while-building-a-apk-in-flutter>

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

## データベース（Supabase）

`supabase_schema/` で実行する。マイグレーションの適用と、pgTAP の実行に使うコマンド。

### リモートへ適用する前に確認する（dry-run）

- 適用される予定のマイグレーションを、実際に流さずに一覧で見る。
- リモートへの `db push` の前に、必ず実行する。

```sh
npx supabase db push --remote --dry-run
```

- `--remote` は、`supabase link` で結び付けたリモートのプロジェクトを指す。CLI v3 から `db push` の既定がローカルの DB に変わったため、リモートへ流すときは必ず付ける。`--linked` と `--project-ref` は非推奨。
- リモートを変更するコマンドは確認を求める（既定は No）。CI など対話しない環境では `--yes` が要る。
- 参考（CLI v3.0.0 の変更点）: [リリースノート](https://github.com/supabase/cli/releases/tag/v3.0.0) / [v2 から v3 への移行ガイド](https://supabase.com/docs/guides/local-development/cli/migrating-to-v3)
- 出力の `Would push these migrations:` に、意図したファイルだけが並んでいることを確認する。
- 意図しないファイルが並んでいたら、`db push` は実行しない。

!!! warning "`db push` は未適用のマイグレーションをまとめて流す"
    - ファイルを指定して、1 本だけ適用することはできない。
    - 一部だけ適用したいときは、適用しないファイルを `supabase/migrations/` の外へ一時的に退避する。
    - 退避したら、もう一度 `--dry-run` で一覧を確認する。適用後に、ファイルを元の場所へ戻す。
    - 例: 旧アプリを壊す「締め付け」のマイグレーションを、新アプリの配布まで保留する。

??? example "1 本だけ適用する手順の例"
    1. 保留するファイルを、リポジトリの外へ移す。
    2. `npx supabase db push --remote --dry-run` で、適用対象を確認する。
    3. `npx supabase db push --remote` で適用する。
    4. 保留したファイルを、`supabase/migrations/` へ戻す。
    5. `git status --short` で、作業ツリーが元に戻ったことを確認する。

### ローカルで検証する

| やりたいこと | コマンド | 補足 |
|---|---|---|
| DB を最初から作り直す | `npm run db:reset` | ローカルのデータは消える。Storage のバックアップと復元、Webhook 用の Vault 登録も行う |
| データを残して新しいマイグレーションだけ適用 | `npx supabase migration up` | |
| pgTAP を実行する | `npx supabase test db` | ローカルの Supabase が起動している必要がある |

!!! note "`supabase test db` はマイグレーションを適用しない"
    - 動いているローカル DB に対してテストを流すだけ。
    - 新しいマイグレーションを足した直後は、先に `db:reset` か `migration up` を実行する。
    - 症状: `function ... does not exist`、ポリシーの件数が期待と違う、権限が残っている。
