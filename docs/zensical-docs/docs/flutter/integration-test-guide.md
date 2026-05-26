# 統合テストガイド

## 概要

`flutter test integration_test/<ファイル名>` コマンドで実機またはエミュレータ上で動作する統合テスト（E2Eテスト）のガイドです。
Firebase・Supabase を含む実際のインフラと通信するため、ユニットテストでは検証できない認証フローや画面遷移を検証します。

---

## ファイル構成

```
integration_test/
  login_flow_test.dart        # ログイン画面のフローテスト
  pay_tab_test.dart           # Payタブ：認証状態による表示切り替えテスト
  app_test.dart               # サンプル：お気に入り操作テスト（flutter.dev チュートリアル由来）
  perf_test.dart              # サンプル：スクロールパフォーマンス計測（flutter.dev チュートリアル由来）
  test_config.dart            # テスト用の認証情報（.gitignore対象）
  test_config.dart.example    # test_config.dart のサンプル（リポジトリ管理）
  helpers/
    auth_helper.dart          # 認証操作の共通ヘルパー
```

> **注意**: `app_test.dart` / `perf_test.dart` は flutter.dev の統合テスト入門チュートリアルをベースにしたサンプルファイルです。本アプリの実際の動作検証には使用していません。

---

## 初期セットアップ

`integration_test/test_config.dart` はリポジトリに含まれていません（`.gitignore` 対象）。
初回のみ以下のコマンドでサンプルからコピーして認証情報を設定してください。

```bash
cp integration_test/test_config.dart.example integration_test/test_config.dart
```

`integration_test/test_config.dart` の内容：

```dart
class TestConfig {
  static const String testEmail = 'your-test-user@example.com'; // Supabaseに登録済みのテストアカウント
  static const String testPassword = 'your-password';           // 正しいパスワード
  static const String wrongPassword = 'wrongpassword';          // 認証失敗ケース用（任意の誤ったパスワード）
}
```

---

## テスト実行方法

エミュレータまたは実機を起動した状態で実行します。

```bash
# フォルダ全体（全ファイル一括実行）
flutter test integration_test/

# ログインフローテスト
flutter test integration_test/login_flow_cases.dart

# Payタブテスト
flutter test integration_test/pay_tab_cases.dart

# モバイルオーダータブテスト
flutter test integration_test/home_mobileorder_tab_cases.dart
```

> **注意**: `app_test.dart` / `perf_test.dart` はサンプルファイルのため、実用テストのみ実行したい場合は個別指定してください。

`dart_test.yaml` に `reporter: expanded` を設定しているため、各テストが独立した行に表示されます。

---

## pay_tab_test.dart の構成

### テストアプリのセットアップ

```dart
Widget buildPayTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(initialLocation: Pay.routeName, routes: AppRouter.routes),
  ),
);
```

- `initialLocation` を `Pay.routeName` にすることで、Payタブを直接起点に起動します
- `AppRouter.routes` を再利用するため `StatefulShellRoute` が正しく解決されます

### 初期化・後処理

| フック | 処理 |
|---|---|
| `setUpAll`（外側） | Firebase・Supabase・Google Sign-In の初期化、GetIt DI コンテナのセットアップ（テストファイル全体で1回のみ） |
| `setUpAll`（b. 認証済み状態 グループ） | `AuthHelper.loginOnce()` で UI なしで Supabase に直接認証（グループで1回のみ） |
| `tearDown` | 各テストケース後に `AuthHelper.logoutTestUser()` でログアウトし、認証状態をリセット |

### テストケース一覧

#### a. 未認証状態

| 項目 | 内容 |
|---|---|
| 目的 | 未ログイン時に正しい UI が表示されることを確認 |
| 前提 | ログアウト状態（tearDown でリセット） |
| 操作 | アプリ起動 → 10秒待機（`connectivityCheckProvider` + `authStateProvider` の解決を待つ） |
| 検証 | `'ご利用にはログインが必要です'` が表示され、`'残高更新'` が非表示であること |

#### b. 認証済み状態

| 項目 | 内容 |
|---|---|
| 目的 | ログイン済み時に正しい UI が表示されることを確認 |
| 前提 | `setUpAll` で `AuthHelper.loginOnce()` により認証済み |
| 操作 | アプリ起動 → 10秒待機（`connectivityCheckProvider` + `authStateProvider` の解決を待つ） |
| 検証 | `'残高更新'` が表示され、`'ご利用にはログインが必要です'` が非表示であること |

### 待機時間について

`pumpAndSettle(const Duration(seconds: 10))` を使用しています。
`connectivityCheckProvider`（ネットワーク確認）と `authStateProvider`（Supabase の Stream）が両方解決するまで待つ必要があります。

---

## login_flow_test.dart の構成

### テストアプリのセットアップ

```dart
Widget buildLoginTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(initialLocation: LoginPage.routeName, routes: AppRouter.routes),
  ),
);
```

- **最小構成のテスト用アプリ**を毎テストケースで生成します
- `AppRouter.routes` を再利用することで、ログイン後の画面遷移も実際のルーティングで動作します
- `ProviderScope` を含むため Riverpod Provider が正常に機能します

### 初期化・後処理

| フック | 処理 |
|---|---|
| `setUpAll` | Firebase・Supabase・Google Sign-In の初期化、GetIt DI コンテナのセットアップ（テストファイル全体で1回のみ実行） |
| `tearDown` | 各テストケース後に `AuthHelper.logoutTestUser()` でログアウトし、認証状態をリセット |

`setUpAll` が1回のみ実行されるのは、Firebase/Supabase の初期化が重く、テストごとに行うと不安定になるためです。

### テストケース一覧

#### a. ログインフォームが表示されること

| 項目 | 内容 |
|---|---|
| 目的 | ログイン画面が正しく描画されるかの基本確認 |
| 前提 | 未ログイン状態 |
| 操作 | アプリ起動 → 5秒待機（生体認証初期化など `initState` の非同期処理完了を待つ） |
| 検証 | メールアドレス入力欄・パスワード入力欄・「ログイン」ボタンが表示されていること |

#### c. メールアドレスが正しくパスワードが間違っている場合はログイン画面にとどまること

| 項目 | 内容 |
|---|---|
| 目的 | 認証失敗時に画面遷移が起きないことを検証 |
| 前提 | 未ログイン状態 |
| 操作 | 正しいメールアドレス + 誤ったパスワードを入力してログインボタンをタップ |
| 検証 | Supabase が認証エラーを返した後もログインフォームが表示されたままであること |
| ヘルパー | `AuthHelper.attemptLoginWithWrongPassword()` |

#### b. 正しいメールアドレスとパスワードでログインするとホーム画面に遷移すること

| 項目 | 内容 |
|---|---|
| 目的 | 正常系のログイン〜画面遷移をエンドツーエンドで検証 |
| 前提 | 未ログイン状態 |
| 操作 | 正しい認証情報を入力 → ログインボタンタップ → ログイン後ダイアログを閉じる |
| 検証 | ホーム画面の `SliverAppBar`（Key: `top_page_sliver_app_bar`）が表示されること |
| ヘルパー | `AuthHelper.loginAsTestUser()` |

> **実行順序について**: c → b の順で定義しています。認証失敗ケースを先に実行することで、ログイン状態のリセット漏れによる影響を受けにくくしています。

---

## helpers/auth_helper.dart の役割

テストコードの重複を避けるための UI 操作・後処理の共通ヘルパークラスです。

### `loginAsTestUser(tester)` — 正常ログイン

```
メールアドレス入力
  ↓ pump × 2（フォームバリデーション状態の反映を待つ）
パスワード入力
  ↓ pump × 2
ヘッダー部分をタップ（キーボードを閉じる）
  ↓ pump 500ms
ログインボタン（FilledButton）をタップ
  ↓ pumpAndSettle 最大15秒（Supabase ネットワーク処理を待つ）
ログイン後ダイアログを dismiss
  ↓ pumpAndSettle 最大5秒（画面遷移アニメーション完了を待つ）
```

**ダイアログ dismiss の対象**:
- `後で` — 指紋認証有効化ダイアログ（生体認証が利用可能な端末で表示）
- `いいえ` — 認証情報保存ダイアログ（生体認証が利用不可な端末で表示）

**pump を2段階に分けている理由**:
`resizeToAvoidBottomInset: false` のログイン画面ではキーボードがボタンを覆うため、キーボードを閉じてからタップする必要があります。また、`_validateForm()` によるボタン有効化の setState 反映を待つために pump が必要です。

### `attemptLoginWithWrongPassword(tester)` — 認証失敗

`loginAsTestUser` と同じ操作手順で `TestConfig.wrongPassword` を使用します。
ログイン失敗のため、ダイアログ dismiss や画面遷移待ちは不要です。

### `loginOnce()` — UI なし直接認証

```
GetIt 経由で AuthService.signInWithEmailAndPassword() を呼び出す
```

ログイン画面を経由せず、Supabase に直接認証します。
`setUpAll` で1回だけ呼ぶことを想定しており、認証状態を前提とするテストグループのセットアップに使用します。
`loginAsTestUser()` と異なり、WidgetTester を必要としないため `setUpAll` からでも呼べます。

### `logoutTestUser()` — ログアウト

UI に依存せず GetIt 経由で `AuthService.signOutWithEmailAndPassword()` を直接呼び出します。
どの画面状態からでも呼べるため、`tearDown` での確実なリセットに適しています。

---

## フレームポリシーの設定（fullyLive）

### 問題: テスト実行中にアニメーションがカクカクして見える

integration_test のデフォルト（`benchmark`）フレームポリシーでは、`pump` 時にのみフレームが描画されます。
その結果、画面遷移・スクロール・アニメーションが「ワープ」するように見え、実際の手動操作と大きくかけ離れた挙動になります。

### 解決策: `fullyLive` ポリシーへの変更

すべてのテストファイルで `fullyLive` を設定することで、全フレームが描画されアニメーションが自然に見えます。

```dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive; // 追加
  ...
}
```

現在は `login_flow_test.dart` / `pay_tab_test.dart` / `app_test.dart` / `perf_test.dart` 全ファイルに設定済みです。

### debugモード vs profileモードの使い分け

`fullyLive` を設定してもビルドモードによる差は残ります。

| 用途 | コマンド | ビルド | アニメーション | 起動速度 |
|---|---|---|---|---|
| **CI / 自動テスト** | `flutter test` | debug（JIT） | `fullyLive` で改善 | 遅い（白画面長い） |
| **開発中の目視確認** | `flutter drive --use-application-binary` | profile（AOT） | 手動操作に近い | 速い |

開発中の目視確認には「Release APK を使った単体ファイル実行」セクションの profile ビルドを推奨します。

### CIでのデフォルト維持

CI では `flutter test`（debug + benchmark）を維持します。見た目のスムーズさは CI では不要であり、実行速度を優先します。

---

## 実装上の注意点・ハマりポイント

### ボタンの有効化タイミング

ログインボタンは `_isFormValid` が `true` になると有効化されます。
`_isFormValid` はメールアドレスとパスワードの両方が入力されたときに `true` になります。
統合テストでは `enterText` 後に `pump()` を呼ばないとボタンが有効化されず、タップが無効になります。

**NG（ボタンが disabled のままタップ）**:
```dart
await tester.enterText(emailField, email);
await tester.enterText(passwordField, password);
await tester.tap(loginButton); // onPressed が null のため何も起きない
```

**OK**:
```dart
await tester.enterText(emailField, email);
await tester.pump();
await tester.pump(const Duration(milliseconds: 300)); // setState 反映を待つ

await tester.enterText(passwordField, password);
await tester.pump();
await tester.pump(const Duration(milliseconds: 300));

await tester.tap(loginButton); // ボタンが有効化されている
```

### ホーム画面の検証に使う Key

`lib/screens/starbucks_user_side/home/main.dart` の `_SliverAppBar` に設定されています。

```dart
SliverAppBar(
  key: const ValueKey('top_page_sliver_app_bar'),
  ...
)
```

`NestedScrollView` のヘッダー部分にあるため、スクロールなしで常に検索対象になります。

### Supabase の待機時間

`pumpAndSettle(const Duration(seconds: 15))` を使用しています。
ネットワーク品質によっては不足する場合があります。CIなどで不安定な場合は時間を増やしてください。

---

## Release APK を使った単体ファイル実行（開発中の目視確認向け）

### 2つの実行方法の使い分け

| 用途 | コマンド | ビルド | 白画面 |
|---|---|---|---|
| **CI / 全体テスト** | `flutter test integration_test/xxx.dart` | debug（自動） | 遅い |
| **開発中の目視確認（単体）** | `flutter drive --use-application-binary` | profile（手動） | 速い |

`flutter test` はデフォルトで debug APK をビルドするため、JIT コンパイルにより起動が遅く白画面が長くなります。
開発中に特定機能を目視確認したい場合は、profile APK + `flutter drive` のフローを使います。

### 仕組み

通常の `flutter build apk` は `lib/main.dart` を entry point とするためテストコードが含まれません。
`--target=integration_test/xxx_test.dart` を指定してビルドすることで、テストを entry point とした APK が生成されます。
`flutter drive` がその APK と通信してテストを実行します。

### 事前準備（1回のみ）

`test_driver/integration_test.dart` がすでに存在します（通常の integration test 用ドライバー）。

```dart
// test_driver/integration_test.dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

> `test_driver/perf_driver.dart` はパフォーマンス計測専用のドライバーです。通常の統合テスト実行には `integration_test.dart` を使います。

### 実行手順

#### Step 1: 対象ファイルの APK をビルド

```bash
flutter build apk --profile \
  --target=integration_test/pay_tab_test.dart \
  --split-per-abi
```

別のテストファイルを実行する場合は `--target` を変更するだけです：

```bash
flutter build apk --profile \
  --target=integration_test/login_flow_test.dart \
  --split-per-abi
```

> **なぜ `--profile` か**
> - release と同等の AOT 性能（白画面が短い）
> - `--obfuscate` 不要でスタックトレースが読める
>
> `--release --obfuscate` は integration test には非推奨です（シンボルが難読化されエラーメッセージが読めなくなります）。

#### Step 2: インストール

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-profile.apk
```

#### Step 3: テスト実行

```bash
flutter drive \
  --use-application-binary=build/app/outputs/flutter-apk/app-arm64-v8a-profile.apk \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/pay_tab_test.dart \
  -d R5CTB2CPS5P
```

デバイス ID は `flutter devices` で確認できます。

### 注意点

- `--target` は 1ファイルのみ指定可能です。複数ファイルはファイルごとにビルド→実行が必要です
- `integration_test/test_config.dart` が存在しないとビルドが失敗します（「初期セットアップ」セクション参照）
