---
description: 開発環境セットアップとプロジェクト情報
---

# 開発環境とプロジェクト情報

## 初回セットアップ: 共有 debug keystore

パスキー・App Links・Google Maps は「このドメイン／APIキーはこの署名鍵のアプリを信頼する」という
登録に依存しており、debug 鍵も登録対象になる。開発者ごとに違う鍵だと登録枠が枯渇するため、
**チーム共通の debug keystore** を使う（Issue #924 4-1 の案A）。

1. Google ドライブの共有ディレクトリから `debug.keystore` を取得する
2. リポジトリの `android/debug.keystore` に置く（gitignore 済み。コミットしない）
3. 正しいファイルか照合する

```bash
keytool -list -v -keystore android/debug.keystore -alias androiddebugkey -storepass android
# SHA-256 が B6:26:8F:61:B8:89:CD:EC:4C:25:6A:41:9C:88:4A:40:E6:BC:67:13:D2:9C:F3:8F:FC:D1:16:1F:F5:79:33:06 であること
```

未配置でも `flutter run` は通る（各自の `~/.android/debug.keystore` にフォールバックする）が、
パスキーが `DomainNotAssociatedException` で動かない。背景・鍵を差し替えるときの手順は
[Android 署名鍵の管理](android-signing-keys.md)を参照。

## Development Commands

### Running the app
- `flutter run` - Run the app in debug mode
- `flutter run --release` - Run in release mode
- `flutter run -d windows` - Run on Windows (if on Windows)

### Testing
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run a specific test file
- `flutter test --coverage` - Run tests with coverage report

### Build Commands
- `flutter build apk` - Build Android APK
- `flutter build appbundle` - Build Android App Bundle
- `flutter build ios` - Build iOS app (macOS only)
- `flutter build web` - Build web version
- `flutter build windows` - Build Windows executable

### Dependencies
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade all dependencies

```bash
dart fix --apply --code=always_use_package_imports
dart fix --apply --code=directives_ordering
dart fix --apply --code=missing_dependency
dart format .
```

These commands will automatically fix common linting issues such as:
- Missing newlines at end of files (`eol_at_end_of_file`)
- Unused imports (`unused_import`)
- Incorrect directive ordering (`directives_ordering`)
- Package import usage (`always_use_package_imports`)

**Note**: While pre-commit hooks are configured to run these commands automatically, Claude Code cannot access git hooks, so manual execution of these commands is necessary before committing changes made through Claude Code.

## Project Architecture

This is a standard Flutter application with the default counter app template. The project follows Flutter's recommended structure:

- `lib/main.dart` - Entry point with MyApp and MyHomePage widgets
- `test/` - Widget and unit tests
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` - Platform-specific configurations

The app uses:
- Material Design with `MaterialApp`
- Stateful widget pattern for the counter functionality
- Standard Flutter project structure and naming conventions
- flutter_lints for code analysis rules

## Key Configurations

- Flutter SDK: ^3.8.0
- Uses Material Design (`uses-material-design: true`)
- Linting: flutter_lints package with default Flutter rules

- Cross-platform support for all major platforms (Android, iOS, Web, Windows, macOS, Linux)
