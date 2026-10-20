# 統合テストガイド

## 概要

`flutter test integration_test/<ファイル名>` コマンドで実機またはエミュレータ上で動作する統合テスト（E2Eテスト）のガイドです。
Firebase・Supabase を含む実際のインフラと通信するため、ユニットテストでは検証できない認証フローや画面遷移を検証します。

---

## ファイル構成

```
integration_test/
  all_tests_test.dart              # 全ケースファイルの集約（フォルダ一括実行の入口）
  login_flow_cases.dart            # ログイン画面のフローテスト（実認証）
  pay_tab_cases.dart               # Payタブ：認証済み状態の表示・支払い動線
  home_mobileorder_tab_cases.dart  # モバイルオーダータブ（実データ依存）
  store_map_tab_cases.dart         # 店舗マップ（GoogleMap の描画がネイティブ依存）
  eticket_cases.dart               # eTicket（実データ依存）
  setting_screen_cases.dart        # 設定画面（実認証依存）
  perf_test.dart                   # サンプル：スクロールパフォーマンス計測（flutter.dev チュートリアル由来）
  test_config.dart                 # テスト用の認証情報（.gitignore対象）
  test_config.dart.example         # test_config.dart のサンプル（リポジトリ管理）
  helpers/
    auth_helper.dart               # 認証操作の共通ヘルパー

test/
  helpers/
    ui_expect.dart                 # 失敗時に画面状態を添えるアサーション／待機ヘルパー
                                   # （Widget テストからも使うため test/ 配下に置く）
    tier1_screen.dart              # 画面1枚を最小構成で描画する Widget テスト用ヘルパー
  screens/starbucks_user_side/
    gift/gift_screen_test.dart     # Tier1（旧 integration_test/gift_tab_cases.dart）
    inbox/main_test.dart           # Tier1（旧 integration_test/inbox_cases.dart）
    rewards/rewards_screen_test.dart # Tier1（旧 integration_test/rewards_screen_cases.dart）
    pay/pay_screen_test.dart       # Tier1（旧 pay_tab_cases.dart の「a. 未認証状態」）
```

> **注意**: `perf_test.dart` は flutter.dev の統合テスト入門チュートリアルをベースにしたサンプルファイルです。本アプリの実際の動作検証には使用していません。

---

## どの Tier に置くか

統合テストは実機・エミュレータが必要で、遅く、実バックエンドの状態に左右されます。
**実バックエンドかネイティブが絡むものだけ**を統合テストに置き、それ以外は Widget テストへ降ろします。

| Tier | 置き場所 | 実行環境 | 対象 |
|---|---|---|---|
| **Tier1** | `test/`（Widget テスト） | `flutter test`（デバイス不要・CI で毎PR） | 画面の描画内容、認証状態などによる UI 分岐、go_router の遷移 |
| **Tier2** | `integration_test/` | 実機・エミュレータ | 実認証フロー、実データ依存、ネイティブ描画（GoogleMap・QR など） |

### Tier1 に降ろせるかの判断

1. その画面が読む Provider を洗い出す（`ref.watch` / `ref.read`）
2. そのすべてを **フェイクに差し替えられる**なら Tier1 に降ろせる
3. 差し替えると検証したい対象そのものが消えるなら Tier2 に残す
   （例: 「実際にログインしたら Supabase の Stream が User を返すこと」）

### フェイクの当て方

差し替えは **画面が実際に読む Provider** で行います。`supabaseClientProvider` だけを差し替える方式は採りません。
キャッシュサービス（`StarPointsCacheService` など）は Supabase だけでなく sqflite にも到達するため、
SupabaseClient を差し替えてもプラットフォームチャネルで落ちます。

```dart
await pumpScreen(
  tester,
  const Rewards(),
  overrides: <Override>[
    starPointsCacheServiceProvider.overrideWithValue(starPoints),
    starAggregationsCacheServiceProvider.overrideWithValue(starAggregations),
  ],
);
```

`Mock implements` はコンストラクタを走らせないので、sqflite にも Supabase にも触れません。

### Tier1 では `AppRouter.routes` を使わない

統合テストは `GoRouter(initialLocation: ..., routes: AppRouter.routes)` を組み、
`StatefulShellRoute` 経由で `ScaffoldWithCustomNavBar` ごと描画します。
このシェルは `initState` の postFrameCallback で `FirebasePerformance.instance` を参照するため、
**Firebase を初期化していない Widget テストでは必ず落ちます**。

Tier1 では `test/helpers/tier1_screen.dart` の `pumpScreen()` を使い、対象画面だけを持つ
最小の `GoRouter` を組みます。ボトムナビとの結線は Tier2 に残ります。

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

Tier1（Widget テスト）はデバイス不要で、通常の `flutter test` に含まれます。

```bash
# Tier1 の画面テストのみ
bash scripts/run-tests.sh test/screens
```

> **注意**: `perf_test.dart` はサンプルファイルのため、実用テストのみ実行したい場合は個別指定してください。

`dart_test.yaml` に `reporter: expanded` を設定しているため、各テストが独立した行に表示されます。

---

## CI での自動実行（nightly）

`.github/workflows/integration-test.yml` が Android エミュレータ上で
`integration_test/all_tests_test.dart` を実行する。

| 項目 | 内容 |
|---|---|
| トリガー | nightly（03:00 JST）と手動実行（`workflow_dispatch`） |
| 対象 | `all_tests_test.dart`（6ファイルの集約） |
| エミュレータ | API 34 / `google_apis` / x86_64 / pixel_6 |
| 出力 | ダイジェスト（job summary + artifact）、`test.json`、`logcat.txt` |

**毎 PR では回さない。** 実 Firebase / Supabase に接続するため遅く、バックエンドの状態に
左右される。PR の速いフィードバックは `test.yml`（Tier1・デバイス不要）が担う。

### なぜ `all_tests_test.dart` を対象にするのか

ファイルごとに `flutter test` を呼ぶとアプリの起動が毎回発生して極端に遅くなる。
集約ファイルなら 1 回の起動で全ケースを回せる。

### 認証情報

`integration_test/test_config.dart` は CI が GitHub の secret から生成する
（`TEST_USER_EMAIL` / `TEST_USER_PASSWORD` / `TEST_USER_WRONG_PASSWORD`。
最後の 1 つは省略時 `wrongpassword`）。

`key.properties` と署名鍵は debug ビルドでは読まれないため用意していない。

### フレークの扱い

失敗の分類が **`infra`（ネットワーク／バックエンド起因）だけ**のときに限り、1 回だけ再実行する
（`scripts/ci-integration-test.sh`）。`assertion` / `timeout` / `crash` / `env` が
混ざっていたら実装かテストの問題なので再実行しない。

**「とりあえずリトライ」は禁止。** 再実行してよい条件はダイジェストの分類で機械的に判定する。

---

## 失敗した理由を読み取る

`flutter test` の標準出力は ok/ng が分かる程度で、「何が NG だったか」を読み取りにくい。
そのため機械可読な JSON レポートを併産し、失敗の要点だけに圧縮したダイジェストを出す。

### 実行

```bash
bash scripts/run-tests.sh                   # 単体・Widget テスト
bash scripts/run-tests.sh integration_test/ # 統合テスト（要 実機/エミュレータ）
```

人間向けの `expanded` 出力はそのまま表示され、加えて以下が生成される。

| 出力 | 内容 |
|---|---|
| `build/reports/test.json` | `--file-reporter=json:` の生レポート |
| `build/reports/digest.md` | 失敗ダイジェスト（CI の artifact 用） |

### ダイジェストの読み方

先頭に 1 行の機械可読サマリが出る。

```
DIGEST_SUMMARY total=42 passed=40 failed=2 skipped=0 classes=assertion:1,infra:1
```

各失敗には**分類**が付く。分類は「次に何をすべきか」と対応している。

| 分類 | 意味 | 取るべき行動 |
|---|---|---|
| `assertion` | expect の不一致 | 期待値と実装のどちらが正しいかを判断して修正する |
| `timeout` | 待機条件が満たされなかった | 待機条件を見直す（**待ち時間を伸ばすだけの修正は禁止**） |
| `env` | 設定ファイル欠落・初期化失敗・コンパイル失敗 | テスト環境を直す。テストコードは触らない |
| `infra` | ネットワーク／バックエンド起因 | 1回だけ再実行する。コードは触らない |
| `crash` | 未捕捉の例外 | 最優先で修正する |

分類ロジックは `tool/src/test_report_digest.dart` にあり、
`test/tool/test_report_digest_test.dart` で検証されている。

---

## アサーションと待機のヘルパー（test/helpers/ui_expect.dart）

素の `expect(find.text('残高更新'), findsOneWidget)` が落ちても、得られるのは
「zero widgets with text "残高更新"」だけで、**画面に何が出ていたのか**が分からない。

### `expectVisible(tester, finder, {matcher, reason})`

`expect` と同じだが、失敗時に「そのとき画面に出ていたテキスト一覧」を必ず添える。
`reason` にはそのアサーションの意図（何を確かめたいのか）を書く。

```dart
expectVisible(
  tester,
  find.text('残高更新'),
  reason: '認証済みなので残高更新が出るはず',
);

expectVisible(
  tester,
  find.text('ご利用にはログインが必要です'),
  matcher: findsNothing,
  reason: '認証済みでログイン促しが出ていたら、認証状態の判定が誤っている',
);
```

画面状態の組み立ては失敗時にしか行わないため、成功時のコストはほぼない。

### `waitUntil(tester, finder, {timeout, interval, reason})`

`finder` が一致するまでフレームを進める。タイムアウト時は、待機対象・待機設定・
実経過時間・そのときの画面テキストを失敗メッセージに残す。

```dart
await waitUntil(
  tester,
  find.byType(QrImageView),
  reason: '支払い画面へ遷移し QR コードが描画されるのを待つ',
);
```

#### ⚠️ 画面遷移のあとは `pumpAndSettle()` も要る

`waitUntil` は **条件が成立した瞬間に返る**。画面遷移の直後だと遷移アニメーションが
まだ進行中で、**前の画面もツリーに残っている**。

```dart
await tester.tap(find.text('支払い'));
await waitUntil(tester, find.byType(QrImageView), reason: '...');

// ここで find.text('支払い') を findsOneWidget で検証すると
// FAB のラベル（fontSize 18）と支払い画面のヘッダー（fontSize 28）の
// 2 件が見つかって落ちる
await tester.pumpAndSettle();   // ← 遷移アニメーションの完了を待つ

expectVisible(tester, find.text('支払い'), reason: '...');
```

**`pumpAndSettle()` は禁止されていない。** 禁止しているのは
**第1引数をタイムアウトのつもりで使うこと**（実際はフレーム間隔）。
役割が違うので使い分ける。

| やりたいこと | 使うもの |
|---|---|
| 要素が出現/消滅したか | `waitUntil` / `waitUntilGone` |
| アニメーションが止まって UI が安定したか | `pumpAndSettle()` |

前の画面の有無に依存しないアサーション（開いたダイアログの中身を見るだけ等）なら
`pumpAndSettle()` は不要。

### `waitUntilGone(tester, finder, {timeout, interval, reason})`

ダイアログを閉じる・ローディングが消えるといった「消滅」の待機に使う。

```dart
await tester.tap(find.text('閉じる'));
await waitUntilGone(
  tester,
  find.byType(AlertDialog),
  reason: '「閉じる」でダイアログが閉じるのを待つ',
);
```

### `visibleTexts(tester)` / `describeScreen(tester)`

現在描画されているテキストの収集と、その要約。上記ヘルパーが内部で使うが、
デバッグ時に直接呼んでもよい。offstage は含めず、重複はあえて残す
（`findsOneWidget` が「2件見つかった」で落ちる状況をそのまま観測するため）。

### 置き場所について

`test/helpers/ui_expect.dart` にある。統合テスト専用ではなく **Widget テストからも使う**ため、
`integration_test/` 配下ではなく `test/` 配下に置いている。
統合テストからは `import '../test/helpers/ui_expect.dart';` で参照する。

### リファレンス実装

- `integration_test/pay_tab_cases.dart` — 統合テスト（Tier2）での利用例（全面移行済み）
- `test/screens/starbucks_user_side/rewards/rewards_screen_test.dart` — Widget テスト（Tier1）での利用例。
  フェイクの当て方と `waitUntilGone` によるローディング待ちを含む
- `test/helpers/ui_expect_test.dart` — ヘルパー自体の検証。
  失敗時にどんなメッセージが出るのかはこのテストが仕様書になっている

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
| `tearDownAll`（b. 認証済み状態 グループ） | `AuthHelper.logoutTestUser()` でログアウトし、認証状態をリセット |

### テストケース一覧

#### a. 未認証状態 → Tier1 へ降格済み

`test/screens/starbucks_user_side/pay/pay_screen_test.dart` に移りました。
未認証時の UI 分岐は実バックエンドに依存しないため、`connectivityCheckProvider` と
`authStateProvider` を差し替えれば Widget テストで検証できます（デバイス不要・CI で毎PR実行）。

実バックエンドから未認証状態が正しく解決されることは `login_flow_cases.dart`
（ログアウト状態から起動してログインフォームが出る）が引き続き Tier2 で担保しています。

#### b. 認証済み状態

| 項目 | 内容 |
|---|---|
| 目的 | ログイン済み時に正しい UI が表示されることを確認 |
| 前提 | `setUpAll` で `AuthHelper.loginOnce()` により認証済み |
| 操作 | アプリ起動 → `waitUntil(find.text('残高更新'))`（`connectivityCheckProvider` + `authStateProvider` の解決を待つ） |
| 検証 | `'残高更新'` が表示され、`'ご利用にはログインが必要です'` が非表示であること |

### 待機について

`connectivityCheckProvider`（ネットワーク確認）と `authStateProvider`（Supabase の Stream）が
両方解決するまで待つ必要があります。この待機は **時間ではなく条件** で表現します。

```dart
await waitUntil(
  tester,
  find.text('残高更新'),
  timeout: const Duration(seconds: 20),
  reason: 'connectivityCheckProvider と authStateProvider が認証済みとして解決するのを待つ',
);
```

`pumpAndSettle(const Duration(seconds: 10))` は使いません。理由は2つあります。

1. **第1引数はタイムアウトではありません。** シグネチャは以下のとおりで、第1引数は
   フレーム間隔、タイムアウトは第3引数（既定 10 分）です。
   「10秒待つ」つもりのコードは実際には「10秒間隔でフレームを進め、最大10分待つ」になります。

    ```dart
    Future<int> pumpAndSettle([
      Duration duration = const Duration(milliseconds: 100),  // フレーム間隔
      EnginePhase phase = EnginePhase.sendSemanticsUpdate,
      Duration timeout = const Duration(minutes: 10),          // タイムアウト
    ])
    ```

2. **失敗しても何を待っていたか分かりません。** `waitUntil` は待機対象・待機設定・
   実経過時間・タイムアウト時の画面テキストを失敗メッセージに残します。

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

ネットワーク品質によって待機時間は変動します。`waitUntil` の `timeout` で上限を指定し、
待機対象は「その処理が終わったことを示す画面要素」を指定してください。

**時間を伸ばすだけの対処は禁止です**（`.claude/rules/quality-gate-layers.md` / Issue #934）。
タイムアウトが頻発する場合は、待っている条件が正しいかをまず疑ってください。

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
