---
description: 開発環境セットアップとプロジェクト情報
---

# 開発環境とプロジェクト情報

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
