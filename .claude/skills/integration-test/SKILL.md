---
name: integration-test
description: |
  Flutter統合テスト（flutter test integration_test/）の作成パターン。
  ログインフローテスト・ログイン済み前提のテスト（ホーム画面以降）の両方に対応。
  トリガーワード: 統合テスト, integration test, e2e, flutter test, ログインスキップ, テスト追加
  典型的なユーザー質問: "統合テストを追加したい", "ログイン後の画面をテストしたい", "AuthHelperの使い方を知りたい"
  【対象外】: unitテスト, widgetテスト, mock, パフォーマンス計測
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Grep
argument-hint: [action]
---

# Flutter 統合テスト スキル

このスキルは、`flutter test integration_test/` による統合テストの作成パターンを提供します。

## 📋 使用場面

- ログインフロー系テスト（現在の `login_flow_test.dart` と同様の新規追加）
- **ログイン済み前提のテスト**（ホーム・注文・マップ等の画面）← 今後のメインユース
- AuthHelper の使い方・拡張が必要な場合

## 引数による実行

**基本形式**: `/integration-test [action]`

| `$1` (action) | 用途 |
|---|---|
| `setup` | テスト環境の初期セットアップ手順 |
| `auth-skipped` | ログイン済み前提のテスト作成パターン |
| `check` | 現在の統合テスト一覧を確認 |
| （引数なし） | 全体概要 + ファイル構成の提示（このドキュメント） |

---

## 📁 プロジェクトのファイル構成

**現在の統合テストファイル**: !`find integration_test -name "*.dart" | sort`

```
integration_test/
  login_flow_test.dart      # ログイン画面フローテスト（実装済み）
  helpers/
    auth_helper.dart        # AuthHelper（共通操作）
test/
  test_config.dart          # 認証情報（.gitignore対象）
  test_config.dart.example  # サンプル（リポジトリ管理対象）
```

---

## ⚙️ テスト環境セットアップ（action=setup）

### 1. test_config.dart の作成

```bash
cp test/test_config.dart.example test/test_config.dart
```

`test/test_config.dart` を開き、実際の認証情報を設定：

```dart
class TestConfig {
  static const String testEmail = 'your-test-user@example.com';
  static const String testPassword = 'your-password';
  static const String wrongPassword = 'wrongpassword';
}
```

> ⚠️ `test/test_config.dart` は `.gitignore` 対象。CI では環境変数から注入が必要。

### 2. エミュレータ起動 → テスト実行

```bash
# エミュレータ起動（Flutter DevTools 経由 or コマンド）
flutter emulators --launch <emulator_id>

# 特定のテストファイルを実行
flutter test integration_test/login_flow_test.dart

# 全統合テストを実行
flutter test integration_test/
```

---

## 🧩 テストアプリの構築パターン

### パターンA: 特定画面から開始（現在の loginFlowTest パターン）

ログインフローのテストなど、**特定の画面から開始したい場合**に使用。

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testingapp/config/app_router.dart';
import 'package:testingapp/screens/starbucks_user_side/signin/login.dart';

Widget buildLoginTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: LoginPage.routeName,
      routes: AppRouter.routes,
    ),
  ),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppInitializer.initializeApp();
    setupLocator();
  });

  tearDown(() async {
    // 各テスト後にログアウトして認証状態をリセット
    await AuthHelper.logoutTestUser();
  });

  group('ログインフロー', () {
    testWidgets('ログインフォームが表示されること', (tester) async {
      await tester.pumpWidget(buildLoginTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // ...
    });
  });
}
```

### パターンB: ログイン済み前提（action=auth-skipped の核心）

ホーム・注文・マップなど、**認証後の画面をテストしたい場合**に使用。
Supabase の実認証を `setUpAll` で1回のみ実行し、各テストで認証状態を維持する。

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:testingapp/config/app_router.dart';

/// 認証済み状態から特定画面を開くテスト用アプリ
Widget buildAuthenticatedTestApp({required String initialLocation}) => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: initialLocation,
      routes: AppRouter.routes,
    ),
  ),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppInitializer.initializeApp();
    setupLocator();
    // UI なしで Supabase 直接ログイン（1回のみ）
    await AuthHelper.loginOnce();
  });

  // tearDown はログアウトしない（認証状態を各テスト間で維持）

  tearDownAll(() async {
    // 最後にまとめてログアウト
    await AuthHelper.logoutTestUser();
  });

  group('ホーム画面', () {
    testWidgets('SliverAppBar が表示されること', (tester) async {
      await tester.pumpWidget(
        buildAuthenticatedTestApp(initialLocation: '/top'),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(
        find.byKey(const ValueKey('top_page_sliver_app_bar')),
        findsOneWidget,
      );
    });
  });
}
```

**なぜこのパターンか**:
- `setUpAll` で認証1回 → 各テストがネットワーク待機不要（高速）
- `tearDown` でログアウトしないことで認証状態を維持
- LoginPage の UI 操作（キーボード、ダイアログ dismiss）が不要

---

## 🔧 AuthHelper の使い方・拡張ガイド

**ファイル**: `integration_test/helpers/auth_helper.dart`

### 既存メソッド

| メソッド | 用途 |
|---|---|
| `loginAsTestUser(tester)` | ログインフロー UI を通じて認証（ログインテスト用） |
| `attemptLoginWithWrongPassword(tester)` | 認証失敗ケースの検証 |
| `logoutTestUser()` | GetIt 経由で AuthService を呼びログアウト |

### 追加提案: `loginOnce()` メソッド

パターンB（ログイン済み前提テスト）で必要になるメソッド。
**実装例**（`auth_helper.dart` に追加）:

```dart
/// UI なしで Supabase に直接ログインする（ログイン済み前提テスト用）。
/// setUpAll() から呼び出し、認証状態を各テスト間で維持する。
static Future<void> loginOnce() async {
  final authService = GetIt.instance<AuthService>();
  await authService.signInWithEmailAndPassword(
    TestConfig.testEmail,
    TestConfig.testPassword,
  );
}
```

> `loginOnce()` は **スキル内にコード例として記載のみ**。実装はテスト追加時に行う。

---

## ⚠️ よくある注意点

### pumpAndSettle の timeout

| 処理 | 推奨 timeout |
|---|---|
| Supabase 認証ネットワーク処理 | `Duration(seconds: 15)` |
| ログイン後の画面遷移・アニメーション | `Duration(seconds: 5)` |
| LoginPage の initState（生体認証初期化） | `Duration(seconds: 5)` |

```dart
// 認証処理
await tester.pumpAndSettle(const Duration(seconds: 15));

// 画面遷移
await tester.pumpAndSettle(const Duration(seconds: 5));
```

### キーボードがボタンを覆う問題

`LoginPage` は `resizeToAvoidBottomInset: false` のため、
テキストフィールド入力後にキーボードがボタンを覆う可能性がある。

**回避方法**: ヘッダー部分をタップしてフォーカスを解除してからボタンをタップ。

```dart
// キーボードを閉じる（ヘッダー部分 y=80 をタップ）
await tester.tapAt(const Offset(200, 80));
await tester.pump(const Duration(milliseconds: 500));

// その後ボタンをタップ
await tester.tap(find.byType(FilledButton));
```

### ボタン有効化の pump タイミング

フォーム入力後、`_validateForm` + `setState` の反映を待つ必要がある。

```dart
await tester.enterText(find.byKey(const Key('login_form_email')), email);
await tester.pump();
await tester.pump(const Duration(milliseconds: 300)); // 反映待ち
```

### ログイン後ダイアログの dismiss

ログイン後に以下のダイアログが表示される場合がある:
- `'後で'` → 指紋認証有効化ダイアログ
- `'いいえ'` → 認証情報保存ダイアログ

`AuthHelper.loginAsTestUser()` は内部で自動的に dismiss する。
パターンB（UI なし認証）では表示されない。

---

## 🔑 ホーム画面の検証 Key

```dart
// lib/screens/starbucks_user_side/home/main.dart の _SliverAppBar に定義
find.byKey(const ValueKey('top_page_sliver_app_bar'))
```

各画面の `ValueKey` は画面実装時に定義し、テストで使用する。

---

## 🔗 詳細ドキュメント

- [統合テストガイド](../../docs/flutter/integration-test-guide.md) - 詳細な実装リファレンス

---

**関連スキル:**
- `/riverpod-3` - Provider・状態管理の実装
- `/code-quality` - Lint 警告対処
