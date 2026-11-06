---
description: 開発環境セットアップとプロジェクト情報
---

# 開発環境とプロジェクト情報

## 初回セットアップ: 共有 debug keystore

- パスキー・App Links・Google Maps は、「このドメイン／API キーは、この署名鍵のアプリを信頼する」という登録に依存している。
- debug 鍵も、登録対象になる。
- 開発者ごとに違う鍵だと、登録枠が枯渇する。そのため、**チーム共通の debug keystore** を使う（Issue #924 4-1 の案A）。

手順:

1. Google ドライブの共有ディレクトリから、`debug.keystore` を取得する。
2. リポジトリの `android/debug.keystore` に置く（gitignore 済み。コミットしない）。
3. 正しいファイルか照合する。

```bash
keytool -list -v -keystore android/debug.keystore -alias androiddebugkey -storepass android
# SHA-256 が B6:26:8F:61:B8:89:CD:EC:4C:25:6A:41:9C:88:4A:40:E6:BC:67:13:D2:9C:F3:8F:FC:D1:16:1F:F5:79:33:06 であること
```

!!! warning "未配置だと、パスキーが動かない"
    - 未配置でも `flutter run` は通る（各自の `~/.android/debug.keystore` にフォールバックする）。
    - ただし、パスキーが `DomainNotAssociatedException` で動かない。
    - 背景と、鍵を差し替えるときの手順は、[Android 署名鍵の管理](../release/android-signing-keys.md)を参照。

## 開発コマンド

- Flutter SDK は FVM で管理している。`flutter` / `dart` は、`fvm flutter` / `fvm dart` に読み替える（[開発環境セットアップ](setup.md)）。

### アプリの実行

- `flutter run`: デバッグモードで実行する。
- `flutter run --release`: リリースモードで実行する。
- `flutter run -d windows`: Windows で実行する（Windows の場合）。

### テスト

- `flutter test`: すべてのテストを実行する。
- `flutter test test/app/launcher_test.dart`: 指定したテストファイルだけを実行する。
- `flutter test --coverage`: カバレッジ付きで実行する。
- テスト戦略とコマンドは、[テスト](../development/testing.md)を参照。

### ビルド

- `flutter build apk`: Android APK をビルドする。
- `flutter build appbundle`: Android App Bundle をビルドする。
- `flutter build ios`: iOS アプリをビルドする（macOS のみ）。
- `flutter build web`: Web 版をビルドする。
- `flutter build windows`: Windows の実行ファイルをビルドする。

### 依存関係

- `flutter pub get`: 依存関係をインストールする。
- `flutter pub upgrade`: 依存関係を更新する。

### lint の自動修正

- 次のコマンドで、lint の指摘を自動修正する。

```bash
dart fix --apply --code=prefer_relative_imports
dart fix --apply --code=directives_ordering
dart fix --apply --code=missing_dependency
dart format .
```

| コマンド | 直すもの |
|---|---|
| `dart fix --apply --code=prefer_relative_imports` | `lib/` 内の import を、相対パスにそろえる |
| `dart fix --apply --code=directives_ordering` | import / export の並び順 |
| `dart fix --apply --code=missing_dependency` | import しているが `pubspec.yaml` に無い依存の追加 |
| `dart format .` | コードの整形（ファイル末尾の改行を含む） |

!!! warning "pre-commit は、自動修正ではなく検査をする"
    - pre-commit（`.githooks/pre-commit`）が行うのは、検査だけ。`dart fix` は実行しない。
        - `dart format --set-exit-if-changed`: 未整形のファイルがあると、コミットが止まる。
        - `dart analyze`: エラーがあると、コミットが止まる。
        - `// ignore:` の混入、`.env`・API キー・秘密鍵の混入。
    - コミットが止まったら、上のコマンドで直してから、もう一度コミットする。
    - hook が未導入なら、`bash scripts/install-git-hooks.sh` で導入する。

!!! note "Claude Code が編集したファイルは、編集の直後に一部が自動修正される"
    - Claude Code の編集直後に、`.claude/hooks/post-tool-use-lint.sh` が、そのファイル 1 つに `dart fix` を実行する。
    - git hooks（pre-commit）は、Claude Code のコミットにも同じように効く。

## プロジェクト構成

- `lib/main.dart` が入口。Crashlytics 付きのエラー処理（`runZonedGuarded`）で包み、`AppInitializer` で Firebase などを初期化してから、`ProviderScope` の下で `TestingApp`（`lib/app/app.dart`）を起動する。
- 主なディレクトリ:

    | ディレクトリ | 役割 |
    |---|---|
    | `lib/app/`・`lib/config/` | アプリの初期化、ルーティング、設定 |
    | `lib/screens/` | 画面（`starbucks_user_side/`、`starbucks_store_side/`） |
    | `lib/provider/` | Riverpod の Provider |
    | `lib/services/`・`lib/core/` | サービス層、モデル |
    | `lib/data/`・`lib/constants/` | データアクセス、定数（Supabase RPC 名など） |
    | `lib/shared/` | 共通ウィジェット・ヘルパー |
    | `test/` | 単体・ウィジェットテスト（`lib/` と同じ構成） |
    | `android/`・`ios/`・`web/`・`windows/`・`macos/`・`linux/` | プラットフォーム別の設定 |

- 各層の役割と実装パターンは、[アーキテクチャ詳細](../architecture/architecture.md)を参照。
- 使っている主な技術:
    - 状態管理: Riverpod 3.0（Notifier API）
    - ルーティング: go_router
    - バックエンド: Supabase
    - UI: Material Design

## 主な設定

| 項目 | 値 | 定義場所 |
|---|---|---|
| Flutter SDK | 3.47.8（FVM で固定） | `pubspec.yaml` の `environment.flutter` |
| Dart SDK | `>=3.10.0 <4.0.0` | `pubspec.yaml` の `environment.sdk` |
| lint | `flutter_lints` + 追加ルール | `analysis_options.yaml` |
| 対応プラットフォーム | Android・iOS・Web・Windows・macOS・Linux | 各プラットフォームのディレクトリ |
