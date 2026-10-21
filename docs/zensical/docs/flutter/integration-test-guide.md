# 統合テストガイド

## 概要

- `flutter test integration_test/<ファイル名>` で、実機またはエミュレータ上で動く統合テスト（E2E テスト）のガイド。
- Firebase・Supabase を含む実際のインフラと通信する。
- ユニットテストでは検証できない、認証フローや画面遷移を検証する。

## ファイル構成

??? info "integration_test/ と test/ のツリー"
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

!!! note "`perf_test.dart` はサンプル"
    - flutter.dev の統合テスト入門チュートリアルをベースにしたサンプルファイル。
    - 本アプリの実際の動作検証には使っていない。

## どの Tier に置くか

- 統合テストは、実機・エミュレータが必要で、遅く、実バックエンドの状態に左右される。
- **実バックエンドかネイティブが絡むものだけ**を統合テストに置く。それ以外は Widget テストに降ろす。

| Tier | 置き場所 | 実行環境 | 対象 |
|---|---|---|---|
| **Tier1** | `test/`（Widget テスト） | `flutter test`（デバイス不要・CI で毎 PR） | 画面の描画内容、認証状態などによる UI 分岐、go_router の遷移 |
| **Tier2** | `integration_test/` | 実機・エミュレータ | 実認証フロー、実データ依存、ネイティブ描画（GoogleMap・QR など） |

### Tier1 に降ろせるかの判断

1. その画面が読む Provider を洗い出す（`ref.watch` / `ref.read`）。
2. そのすべてを **フェイクに差し替えられる**なら、Tier1 に降ろせる。
3. 差し替えると、検証したい対象そのものが消えるなら、Tier2 に残す。
    - 例: 「実際にログインしたら Supabase の Stream が User を返すこと」。

### フェイクの当て方

- 差し替えは **画面が実際に読む Provider** で行う。
- `supabaseClientProvider` だけを差し替える方式は採らない。
    - キャッシュサービス（`StarPointsCacheService` など）は、Supabase だけでなく sqflite にも到達する。
    - そのため SupabaseClient を差し替えても、プラットフォームチャネルで落ちる。
- `Mock implements` はコンストラクタを走らせないので、sqflite にも Supabase にも触れない。

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

!!! warning "Tier1 では `AppRouter.routes` を使わない"
    - 統合テストは `GoRouter(initialLocation: ..., routes: AppRouter.routes)` を組み、`StatefulShellRoute` 経由で `ScaffoldWithCustomNavBar` ごと描画する。
    - このシェルは、`initState` の postFrameCallback で `FirebasePerformance.instance` を参照する。
    - そのため、**Firebase を初期化していない Widget テストでは必ず落ちる**。
    - Tier1 では `test/helpers/tier1_screen.dart` の `pumpScreen()` を使い、対象画面だけを持つ最小の `GoRouter` を組む。
    - ボトムナビとの結線は、Tier2 に残る。

## 初期セットアップ

- `integration_test/test_config.dart` はリポジトリに含まれない（`.gitignore` 対象）。
- 初回のみ、サンプルからコピーして認証情報を設定する。

```bash
cp integration_test/test_config.dart.example integration_test/test_config.dart
```

`integration_test/test_config.dart` の内容:

```dart
class TestConfig {
  static const String testEmail = 'your-test-user@example.com'; // Supabaseに登録済みのテストアカウント
  static const String testPassword = 'your-password';           // 正しいパスワード
  static const String wrongPassword = 'wrongpassword';          // 認証失敗ケース用（任意の誤ったパスワード）
}
```

## テスト実行方法

エミュレータまたは実機を起動した状態で実行する。

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

- Tier1（Widget テスト）は、デバイス不要。通常の `flutter test` に含まれる。

```bash
# Tier1 の画面テストのみ
bash scripts/run-tests.sh test/screens
```

- `dart_test.yaml` に `reporter: expanded` を設定しているため、各テストが独立した行に表示される。

!!! tip "実用テストだけを実行したいとき"
    `perf_test.dart` はサンプルファイルなので、個別にファイルを指定する。

## CI での自動実行（nightly）

- `.github/workflows/integration-test.yml` が、Android エミュレータ上で `integration_test/all_tests_test.dart` を実行する。

| 項目 | 内容 |
|---|---|
| トリガー | nightly（03:00 JST）と手動実行（`workflow_dispatch`） |
| 対象 | `all_tests_test.dart`（6 ファイルの集約） |
| エミュレータ | API 34 / `google_apis` / x86_64 / pixel_6 |
| 出力 | ダイジェスト（job summary + artifact）、`test.json`、`logcat.txt` |

!!! warning "毎 PR では回さない"
    - 実 Firebase / Supabase に接続するため遅く、バックエンドの状態に左右される。
    - PR の速いフィードバックは、`test.yml`（Tier1・デバイス不要）が担う。

### なぜ `all_tests_test.dart` を対象にするのか

- ファイルごとに `flutter test` を呼ぶと、アプリの起動が毎回発生して極端に遅くなる。
- 集約ファイルなら、1 回の起動で全ケースを回せる。

### 認証情報

- `integration_test/test_config.dart` は、CI が GitHub の secret から生成する。
    - `TEST_USER_EMAIL` / `TEST_USER_PASSWORD` / `TEST_USER_WRONG_PASSWORD`。
    - 最後の 1 つは省略時 `wrongpassword`。
- `key.properties` と署名鍵は、debug ビルドでは読まれないため用意していない。

### フレークの扱い

- 失敗の分類が **`infra`（ネットワーク / バックエンド起因）だけ**のときに限り、1 回だけ再実行する（`scripts/ci-integration-test.sh`）。
- `assertion` / `timeout` / `crash` / `env` が混ざっていたら、実装かテストの問題なので再実行しない。

!!! danger "「とりあえずリトライ」は禁止"
    再実行してよい条件は、ダイジェストの分類で機械的に判定する。

## 失敗した理由を読み取る

- `flutter test` の標準出力は ok / ng が分かる程度で、「何が NG だったか」を読み取りにくい。
- そのため、機械可読な JSON レポートを併せて作り、失敗の要点だけに圧縮したダイジェストを出す。

### 実行

```bash
bash scripts/run-tests.sh                   # 単体・Widget テスト
bash scripts/run-tests.sh integration_test/ # 統合テスト（要 実機/エミュレータ）
```

- 人間向けの `expanded` 出力はそのまま表示される。加えて、次が生成される。

| 出力 | 内容 |
|---|---|
| `build/reports/test.json` | `--file-reporter=json:` の生レポート |
| `build/reports/digest.md` | 失敗ダイジェスト（CI の artifact 用） |

### ダイジェストの読み方

先頭に、1 行の機械可読サマリが出る。

```
DIGEST_SUMMARY total=42 passed=40 failed=2 skipped=0 classes=assertion:1,infra:1
```

各失敗には**分類**が付く。分類は「次に何をすべきか」と対応している。

| 分類 | 意味 | 取るべき行動 |
|---|---|---|
| `assertion` | expect の不一致 | 期待値と実装のどちらが正しいかを判断して修正する |
| `timeout` | 待機条件が満たされなかった | 待機条件を見直す（**待ち時間を伸ばすだけの修正は禁止**） |
| `env` | 設定ファイル欠落・初期化失敗・コンパイル失敗 | テスト環境を直す。テストコードは触らない |
| `infra` | ネットワーク / バックエンド起因 | 1 回だけ再実行する。コードは触らない |
| `crash` | 未捕捉の例外 | 最優先で修正する |

- 分類ロジックは `tool/src/test_report_digest.dart` にある。
- `test/tool/test_report_digest_test.dart` で検証されている。

## アサーションと待機のヘルパー（test/helpers/ui_expect.dart）

- 素の `expect(find.text('残高更新'), findsOneWidget)` が落ちても、得られるのは「zero widgets with text "残高更新"」だけ。
- **画面に何が出ていたのか**が分からない。そのため、次のヘルパーを使う。

| ヘルパー | 用途 |
|---|---|
| `expectVisible` | `expect` と同じだが、失敗時に画面のテキスト一覧を添える |
| `waitUntil` | `finder` が一致するまでフレームを進める |
| `waitUntilGone` | 「消滅」を待つ（ダイアログを閉じる、ローディングが消える） |
| `visibleTexts` / `describeScreen` | 描画中のテキストの収集と要約（上記が内部で使う） |

### `expectVisible(tester, finder, {matcher, reason})`

- `expect` と同じだが、失敗時に「そのとき画面に出ていたテキスト一覧」を必ず添える。
- `reason` には、そのアサーションの意図（何を確かめたいのか）を書く。
- 画面状態の組み立ては失敗時にしか行わない。成功時のコストはほぼない。

??? example "コード例（12 行）"
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

### `waitUntil(tester, finder, {timeout, interval, reason})`

- `finder` が一致するまで、フレームを進める。
- タイムアウト時は、次を失敗メッセージに残す。
    - 待機対象
    - 待機設定
    - 実経過時間
    - そのときの画面テキスト

```dart
await waitUntil(
  tester,
  find.byType(QrImageView),
  reason: '支払い画面へ遷移し QR コードが描画されるのを待つ',
);
```

!!! warning "画面遷移のあとは `pumpAndSettle()` も要る"
    - `waitUntil` は **条件が成立した瞬間に返る**。
    - 画面遷移の直後は、遷移アニメーションがまだ進行中で、**前の画面もツリーに残っている**。

    ```dart
    await tester.tap(find.text('支払い'));
    await waitUntil(tester, find.byType(QrImageView), reason: '...');

    // ここで find.text('支払い') を findsOneWidget で検証すると
    // FAB のラベル（fontSize 18）と支払い画面のヘッダー（fontSize 28）の
    // 2 件が見つかって落ちる
    await tester.pumpAndSettle();   // ← 遷移アニメーションの完了を待つ

    expectVisible(tester, find.text('支払い'), reason: '...');
    ```

- **`pumpAndSettle()` は禁止されていない。**
- 禁止しているのは、**第 1 引数をタイムアウトのつもりで使うこと**（実際はフレーム間隔）。
- 役割が違うので、使い分ける。

| やりたいこと | 使うもの |
|---|---|
| 要素が出現 / 消滅したか | `waitUntil` / `waitUntilGone` |
| アニメーションが止まって UI が安定したか | `pumpAndSettle()` |

- 前の画面の有無に依存しないアサーション（開いたダイアログの中身を見るだけ、など）なら、`pumpAndSettle()` は不要。

### `waitUntilGone(tester, finder, {timeout, interval, reason})`

- ダイアログを閉じる、ローディングが消える、といった「消滅」の待機に使う。

```dart
await tester.tap(find.text('閉じる'));
await waitUntilGone(
  tester,
  find.byType(AlertDialog),
  reason: '「閉じる」でダイアログが閉じるのを待つ',
);
```

### `visibleTexts(tester)` / `describeScreen(tester)`

- 現在描画されているテキストの収集と、その要約。
- 上記のヘルパーが内部で使う。デバッグ時に直接呼んでもよい。
- offstage は含めない。
- 重複はあえて残す（`findsOneWidget` が「2 件見つかった」で落ちる状況を、そのまま観測するため）。

### 置き場所

- `test/helpers/ui_expect.dart` にある。
- 統合テスト専用ではなく **Widget テストからも使う**ため、`integration_test/` ではなく `test/` 配下に置いている。
- 統合テストからは `import '../test/helpers/ui_expect.dart';` で参照する。

### リファレンス実装

- `integration_test/pay_tab_cases.dart`: 統合テスト（Tier2）での利用例（全面移行済み）。
- `test/screens/starbucks_user_side/rewards/rewards_screen_test.dart`: Widget テスト（Tier1）での利用例。フェイクの当て方と、`waitUntilGone` によるローディング待ちを含む。
- `test/helpers/ui_expect_test.dart`: ヘルパー自体の検証。失敗時にどんなメッセージが出るのかは、このテストが仕様書になっている。

## pay_tab_test.dart の構成

### テストアプリのセットアップ

```dart
Widget buildPayTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(initialLocation: Pay.routeName, routes: AppRouter.routes),
  ),
);
```

- `initialLocation` を `Pay.routeName` にして、Pay タブを直接の起点に起動する。
- `AppRouter.routes` を再利用するため、`StatefulShellRoute` が正しく解決される。

### 初期化・後処理

| フック | 処理 |
|---|---|
| `setUpAll`（外側） | Firebase・Supabase・Google Sign-In の初期化、GetIt DI コンテナのセットアップ（テストファイル全体で 1 回のみ） |
| `setUpAll`（b. 認証済み状態 グループ） | `AuthHelper.loginOnce()` で、UI なしで Supabase に直接認証（グループで 1 回のみ） |
| `tearDownAll`（b. 認証済み状態 グループ） | `AuthHelper.logoutTestUser()` でログアウトし、認証状態をリセット |

### テストケース一覧

#### a. 未認証状態 → Tier1 へ降格済み

- `test/screens/starbucks_user_side/pay/pay_screen_test.dart` に移った。
- 未認証時の UI 分岐は実バックエンドに依存しない。`connectivityCheckProvider` と `authStateProvider` を差し替えれば、Widget テストで検証できる（デバイス不要・CI で毎 PR 実行）。
- 実バックエンドから未認証状態が正しく解決されることは、`login_flow_cases.dart`（ログアウト状態から起動してログインフォームが出る）が、引き続き Tier2 で担保している。

#### b. 認証済み状態

| 項目 | 内容 |
|---|---|
| 目的 | ログイン済み時に、正しい UI が表示されることを確認 |
| 前提 | `setUpAll` で `AuthHelper.loginOnce()` により認証済み |
| 操作 | アプリ起動 → `waitUntil(find.text('残高更新'))`（`connectivityCheckProvider` + `authStateProvider` の解決を待つ） |
| 検証 | `'残高更新'` が表示され、`'ご利用にはログインが必要です'` が非表示であること |

### 待機について

- `connectivityCheckProvider`（ネットワーク確認）と `authStateProvider`（Supabase の Stream）が、両方解決するまで待つ必要がある。
- この待機は、**時間ではなく条件**で表現する。

```dart
await waitUntil(
  tester,
  find.text('残高更新'),
  timeout: const Duration(seconds: 20),
  reason: 'connectivityCheckProvider と authStateProvider が認証済みとして解決するのを待つ',
);
```

!!! danger "`pumpAndSettle(const Duration(seconds: 10))` は使わない"
    理由は 2 つ。

    1. **第 1 引数はタイムアウトではない。**
        - シグネチャは下のとおり。第 1 引数はフレーム間隔で、タイムアウトは第 3 引数（既定 10 分）。
        - 「10 秒待つ」つもりのコードは、実際には「10 秒間隔でフレームを進め、最大 10 分待つ」になる。
    2. **失敗しても、何を待っていたか分からない。**
        - `waitUntil` は、待機対象・待機設定・実経過時間・タイムアウト時の画面テキストを、失敗メッセージに残す。

    ```dart
    Future<int> pumpAndSettle([
      Duration duration = const Duration(milliseconds: 100),  // フレーム間隔
      EnginePhase phase = EnginePhase.sendSemanticsUpdate,
      Duration timeout = const Duration(minutes: 10),          // タイムアウト
    ])
    ```

## login_flow_test.dart の構成

### テストアプリのセットアップ

```dart
Widget buildLoginTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(initialLocation: LoginPage.routeName, routes: AppRouter.routes),
  ),
);
```

- **最小構成のテスト用アプリ**を、毎テストケースで生成する。
- `AppRouter.routes` を再利用するため、ログイン後の画面遷移も実際のルーティングで動く。
- `ProviderScope` を含むため、Riverpod の Provider が正常に機能する。

### 初期化・後処理

| フック | 処理 |
|---|---|
| `setUpAll` | Firebase・Supabase・Google Sign-In の初期化、GetIt DI コンテナのセットアップ（テストファイル全体で 1 回のみ実行） |
| `tearDown` | 各テストケース後に `AuthHelper.logoutTestUser()` でログアウトし、認証状態をリセット |

- `setUpAll` が 1 回だけなのは、Firebase / Supabase の初期化が重く、テストごとに行うと不安定になるため。

### テストケース一覧

??? info "a. ログインフォームが表示されること"
    | 項目 | 内容 |
    |---|---|
    | 目的 | ログイン画面が正しく描画されるかの基本確認 |
    | 前提 | 未ログイン状態 |
    | 操作 | アプリ起動 → 5 秒待機（生体認証初期化など `initState` の非同期処理完了を待つ） |
    | 検証 | メールアドレス入力欄・パスワード入力欄・「ログイン」ボタンが表示されていること |

??? info "c. メールアドレスが正しくパスワードが間違っている場合はログイン画面にとどまること"
    | 項目 | 内容 |
    |---|---|
    | 目的 | 認証失敗時に、画面遷移が起きないことを検証 |
    | 前提 | 未ログイン状態 |
    | 操作 | 正しいメールアドレス + 誤ったパスワードを入力してログインボタンをタップ |
    | 検証 | Supabase が認証エラーを返した後も、ログインフォームが表示されたままであること |
    | ヘルパー | `AuthHelper.attemptLoginWithWrongPassword()` |

??? info "b. 正しいメールアドレスとパスワードでログインするとホーム画面に遷移すること"
    | 項目 | 内容 |
    |---|---|
    | 目的 | 正常系のログイン〜画面遷移を、エンドツーエンドで検証 |
    | 前提 | 未ログイン状態 |
    | 操作 | 正しい認証情報を入力 → ログインボタンをタップ → ログイン後ダイアログを閉じる |
    | 検証 | ホーム画面の `SliverAppBar`（Key: `top_page_sliver_app_bar`）が表示されること |
    | ヘルパー | `AuthHelper.loginAsTestUser()` |

!!! note "実行順序: c → b の順で定義している"
    認証失敗ケースを先に実行することで、ログイン状態のリセット漏れによる影響を受けにくくしている。

## helpers/auth_helper.dart の役割

テストコードの重複を避けるための、UI 操作・後処理の共通ヘルパークラス。

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

- **ダイアログ dismiss の対象:**
    - `後で`: 指紋認証有効化ダイアログ（生体認証が使える端末で表示）。
    - `いいえ`: 認証情報保存ダイアログ（生体認証が使えない端末で表示）。

!!! note "pump を 2 段階に分けている理由"
    - `resizeToAvoidBottomInset: false` のログイン画面では、キーボードがボタンを覆う。そのため、キーボードを閉じてからタップする必要がある。
    - また、`_validateForm()` によるボタン有効化の `setState` 反映を待つために、pump が必要。

### `attemptLoginWithWrongPassword(tester)` — 認証失敗

- `loginAsTestUser` と同じ操作手順で、`TestConfig.wrongPassword` を使う。
- ログイン失敗のため、ダイアログの dismiss や画面遷移待ちは不要。

### `loginOnce()` — UI なし直接認証

```
GetIt 経由で AuthService.signInWithEmailAndPassword() を呼び出す
```

- ログイン画面を経由せず、Supabase に直接認証する。
- `setUpAll` で 1 回だけ呼ぶ想定。認証状態を前提とするテストグループのセットアップに使う。
- `loginAsTestUser()` と違い、`WidgetTester` を必要としないので、`setUpAll` からでも呼べる。

### `logoutTestUser()` — ログアウト

- UI に依存せず、GetIt 経由で `AuthService.signOutWithEmailAndPassword()` を直接呼ぶ。
- どの画面状態からでも呼べるため、`tearDown` での確実なリセットに向く。

## フレームポリシーの設定（fullyLive）

### 問題: テスト実行中にアニメーションがカクカクして見える

- integration_test の既定（`benchmark`）のフレームポリシーでは、`pump` 時にだけフレームが描画される。
- その結果、画面遷移・スクロール・アニメーションが「ワープ」するように見える。実際の手動操作と大きくかけ離れた挙動になる。

### 解決策: `fullyLive` ポリシーへの変更

- すべてのテストファイルで `fullyLive` を設定すると、全フレームが描画され、アニメーションが自然に見える。

```dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive; // 追加
  ...
}
```

- 現在は、`login_flow_test.dart` / `pay_tab_test.dart` / `app_test.dart` / `perf_test.dart` の全ファイルに設定済み。

### debug モードと profile モードの使い分け

- `fullyLive` を設定しても、ビルドモードによる差は残る。

| 用途 | コマンド | ビルド | アニメーション | 起動速度 |
|---|---|---|---|---|
| **CI / 自動テスト** | `flutter test` | debug（JIT） | `fullyLive` で改善 | 遅い（白画面が長い） |
| **開発中の目視確認** | `flutter drive --use-application-binary` | profile（AOT） | 手動操作に近い | 速い |

- 開発中の目視確認には、「Release APK を使った単体ファイル実行」の profile ビルドを推奨する。

!!! note "CI ではデフォルトを維持する"
    - CI では `flutter test`（debug + benchmark）を維持する。
    - 見た目のスムーズさは CI では不要で、実行速度を優先するため。

## 実装上の注意点・ハマりポイント

### ボタンの有効化タイミング

- ログインボタンは、`_isFormValid` が `true` になると有効化される。
- `_isFormValid` は、メールアドレスとパスワードの両方が入力されたときに `true` になる。
- 統合テストでは、`enterText` の後に `pump()` を呼ばないとボタンが有効化されず、タップが無効になる。

??? failure "NG: ボタンが disabled のままタップ"
    ```dart
    await tester.enterText(emailField, email);
    await tester.enterText(passwordField, password);
    await tester.tap(loginButton); // onPressed が null のため何も起きない
    ```

??? success "OK: pump で setState の反映を待つ"
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

- `lib/screens/starbucks_user_side/home/main.dart` の `_SliverAppBar` に設定されている。

```dart
SliverAppBar(
  key: const ValueKey('top_page_sliver_app_bar'),
  ...
)
```

- `NestedScrollView` のヘッダー部分にあるため、スクロールなしで常に検索対象になる。

### Supabase の待機時間

- ネットワーク品質によって、待機時間は変動する。
- `waitUntil` の `timeout` で上限を指定する。
- 待機対象は、「その処理が終わったことを示す画面要素」を指定する。

!!! danger "時間を伸ばすだけの対処は禁止（`.claude/rules/quality-gate-layers.md` / Issue #934）"
    タイムアウトが頻発する場合は、待っている条件が正しいかをまず疑う。

## Release APK を使った単体ファイル実行（開発中の目視確認向け）

### 2 つの実行方法の使い分け

| 用途 | コマンド | ビルド | 白画面 |
|---|---|---|---|
| **CI / 全体テスト** | `flutter test integration_test/xxx.dart` | debug（自動） | 遅い |
| **開発中の目視確認（単体）** | `flutter drive --use-application-binary` | profile（手動） | 速い |

- `flutter test` は、既定で debug APK をビルドする。JIT コンパイルにより起動が遅く、白画面が長くなる。
- 開発中に特定機能を目視確認したいときは、profile APK + `flutter drive` のフローを使う。

### 仕組み

- 通常の `flutter build apk` は、`lib/main.dart` を entry point とするため、テストコードが含まれない。
- `--target=integration_test/xxx_test.dart` を指定してビルドすると、テストを entry point とした APK ができる。
- `flutter drive` が、その APK と通信してテストを実行する。

### 事前準備（1 回のみ）

- `test_driver/integration_test.dart` は、すでに存在する（通常の integration test 用ドライバー）。

```dart
// test_driver/integration_test.dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

!!! note "ドライバーの使い分け"
    `test_driver/perf_driver.dart` は、パフォーマンス計測専用のドライバー。通常の統合テスト実行には `integration_test.dart` を使う。

### 実行手順

#### Step 1: 対象ファイルの APK をビルド

```bash
flutter build apk --profile \
  --target=integration_test/pay_tab_test.dart \
  --split-per-abi
```

- 別のテストファイルを実行するときは、`--target` を変えるだけ。

```bash
flutter build apk --profile \
  --target=integration_test/login_flow_test.dart \
  --split-per-abi
```

!!! tip "なぜ `--profile` か"
    - release と同等の AOT 性能（白画面が短い）。
    - `--obfuscate` 不要で、スタックトレースが読める。
    - `--release --obfuscate` は、integration test には非推奨（シンボルが難読化され、エラーメッセージが読めなくなる）。

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

- デバイス ID は `flutter devices` で確認できる。

### 注意点

- `--target` は 1 ファイルのみ指定できる。複数ファイルは、ファイルごとにビルド → 実行が必要。
- `integration_test/test_config.dart` が無いと、ビルドが失敗する（「初期セットアップ」を参照）。
