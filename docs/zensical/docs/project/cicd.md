# CI/CD - GitHub Actions

## ワークフローファイル一覧

本プロジェクトで使っている GitHub Actions ワークフローの一覧。各ワークフローの詳細は、折り畳みの中にある。

| ワークフロー名 | ファイル名 | トリガー | 用途 |
|--------------|-----------|---------|------|
| Flutter CI/CD | [`app.yml`](#appyml) | 手動実行 | APKビルド・App Distributionへの配布 |
| Test | [`test.yml`](#testyml) | main push / PR / 手動 | 静的解析・単体/Widgetテスト（デバイス不要） |
| Integration Test | [`integration-test.yml`](#integration-testyml) | 毎日 03:00 JST / 手動 | Androidエミュレータでの統合テスト |
| Deploy Edge Functions | [`deploy-edge-functions.yml`](#deploy-edge-functionsyml) | main push / PR / 手動 | Supabase Edge Functionsの型チェックとデプロイ |
| Deploy Firebase Functions | [`deploy-firebase-functions.yml`](#deploy-firebase-functionsyml) | main push / PR / 手動 | Crashlyticsアラート→Issue変換のCloud Functionsデプロイ |
| Deploy Firebase Hosting | [`deploy-firebase-hosting.yml`](#deploy-firebase-hostingyml) | main push / 手動 | assetlinks.jsonのデプロイとRP Origins同期 |
| Deploy Order Assistant | [`deploy-order-assistant.yml`](#deploy-order-assistantyml) | main push / PR / 手動 | 会話注文サーバーのCloud Runデプロイ |
| Schema Docs | [`schema-docs.yml`](#schema-docsyml) | PR / 手動 | テーブル定義書・ER図の更新漏れ検出 |
| Design Tokens | [`design-tokens.yml`](#design-tokensyml) | PR / 手動 | デザイントークン生成物の再生成 |
| Documentation | [`docs.yml`](#docsyml) | main push / 手動 | ドキュメントサイトのGitHub Pages公開 |
| Documentation Sync | [`documentation-sync.yaml`](#documentation-syncyaml) | PR | 画面/サービス変更時のdocs自動更新 |
| Revert Commit | [`revert-to-commit.yml`](#revert-to-commityml) | 手動実行 | 特定コミットへの巻き戻し |
| Claude Support | [`claude.yml`](#claudeyml) | `@claude`メンション | Issue/PRでのAI支援 |
| AI Code Review | [`claude-code-review.yml`](#claude-code-reviewyml) | PRのオープン/更新 | 自動コードレビュー |

## `app.yml`
- Flutter アプリケーションのAPKビルドとFirebase App Distributionへの配布を行います。
- push では回さない。
- テストはPR/push向けの[`test.yml`](#testyml)が担う。

??? info "詳細（トリガー・処理内容・Secrets）"

    **トリガー条件:**

    - 手動実行（`workflow_dispatch`）のみ。pushトリガーはコメントアウトしてある

    **実行時の入力:**

    | 入力 | 既定 | 説明 |
    |---|---|---|
    | `run_tests` | true | `flutter test` を実行する |
    | `build_apk` | true | APKをビルドする |
    | `distribute` | true | Firebase App Distributionへ配布する |
    | `release_notes` | 空 | 配布時のリリースノート。省略時はブランチ名とコミットハッシュ |

    **主な処理内容:**

    1. **環境セットアップ**
        - Flutter 3.47.7のインストール
        - Android SDKのセットアップ
        - 各種キャッシュの復元（依存関係、Gradle、Android SDK）

    2. **シークレット情報の復元**
        - `google-services.json`の復元（Base64デコード）
        - リリース用Keystoreファイルの作成
        - `key.properties`の生成（署名情報）
        - `secrets.properties`の生成（Maps API Key等）
        - `.env`ファイルの生成（Supabase、Firebase、Order Assistant等の接続情報）

    3. **ビルドプロセス**
        - `build_runner`の実行（コード生成）
        - テストの実行（`flutter test`）
        - APKのビルド（ABI別、難読化あり）

    4. **配布**
        - APK署名証明書のSHA-256を`assetlinks.json`の`get_login_creds`と照合（未登録なら警告）
        - Firebase App Distributionへの配布（`app-arm64-v8a-release.apk`をグループ`testers`へ）
        - ビルド成果物のクリーンアップ

    !!! note "APKをArtifactsに置かない"

        - APK は 1 ファイル約 40MB ある。毎回 Artifacts に上げると、Free プランのストレージ上限に到達する。
        - 成果物の受け渡しは App Distribution 側に寄せているため、`Upload APK` ステップは意図的に持たない。
        - 詳細は [Android 署名鍵の管理](android-signing-keys.md) を参照。

    **必要なGitHub Secrets:**

    - 認証情報: `GOOGLE_SERVICES_JSON`, `RELEASE_KEYSTORE`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`
    - API Keys: `MAPS_API_KEY`
    - Firebase: `FIREBASE_APP_ID`, `FIREBASE_HOSTING_DOMAIN`, `CREDENTIAL_FILE_CONTENT`
    - Supabase: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
    - Google認証: `GOOGLE_CLIENT_ID`, `GOOGLE_WEB_SERVER_CLIENT_ID`
    - その他: `STARBUCKS_WEB_URL`, `SSL_SHA256_FINGER_PRINT`, `ORDER_ASSISTANT_URL`


## `claude.yml`
- IssueやPRのコメントで`@claude`とメンションすることで、Claudeによる支援を受けられます。

??? info "詳細（トリガー・処理内容・Secrets）"

    **トリガー条件:**

    - Issueコメントに`@claude`が含まれる時
    - PRレビューコメントに`@claude`が含まれる時
    - PRレビュー本文に`@claude`が含まれる時
    - Issueのタイトル・本文に`@claude`が含まれる時

    **主な処理内容:**

    - Claude Code Actionの実行（最大30ターン。調査だけでなく修正の実装とPR作成まで行う）
    - モデル: 別名`sonnet`（リポジトリの`.claude/rules/model-routing.md`に従い、フルIDは直書きしない）
    - Crashlyticsアラート由来のIssue（[`deploy-firebase-functions.yml`](#deploy-firebase-functionsyml)が作成）への自動修復もこのワークフローが受ける

    **必要なGitHub Secrets:**

    - `ANTHROPIC_API_KEY`


## `claude-code-review.yml`
- PRの差分を自動的にレビューし、改善提案をコメントします。

??? info "詳細（トリガー・処理内容・Secrets）"

    **トリガー条件:**

    - PRのオープン・同期時（作成者による絞り込みはコメントアウトしてあり、全PRが対象）

    **主な処理内容:**

    - `anthropics/claude-code-action`でPRの差分を確認
    - `lib/`の変更に対応する設計ドキュメント（`docs/`配下）の作成・更新を促し、結果を`gh pr comment`で投稿

    **必要なGitHub Secrets:**

    - `ANTHROPIC_API_KEY`


## `revert-to-commit.yml`
- mainブランチの特定のコミットまで状態を戻すためのワークフローです。

??? info "詳細（トリガー・処理内容・Secrets）"

    **入力パラメータ:**

    - `commit_hash` (必須): 戻したいコミットのハッシュ値
    - `create_pr` (任意): PRを作成するかどうか（デフォルト: true）
        - `true`: revertブランチを作成してPRを作成（推奨）
        - `false`: mainブランチに直接マージ

    **主な処理内容:**

    1. **環境セットアップ**
        - リポジトリの全履歴を取得（`fetch-depth: 0`）
        - Git設定（github-actions botとして実行）

    2. **Revert処理**
        - 指定されたコミットの存在確認
        - `revert-to-{commit_hash}`という名前のブランチを作成
        - 指定コミット以降の変更をrevert（`git revert --no-commit`）
        - revertコミットを作成

    3. **変更の反映**
        - `create_pr=true`の場合: PRを作成してレビュー待ち
        - `create_pr=false`の場合: mainブランチに直接マージしてpush

    **使用方法:**

    1. GitHub リポジトリの **Actions** タブを開く
    2. 左メニューから **Revert to Commit** を選択
    3. **Run workflow** をクリック
    4. コミットハッシュを入力（例: `aa03c60` または完全なハッシュ）
    5. PR作成の有無を選択
    6. **Run workflow** を実行

    **必要な権限:**

    - `contents: write` - リポジトリへの書き込み権限
    - `pull-requests: write` - PR作成権限

    **注意事項:**

    - 本番環境では必ず `create_pr=true` で実行し、レビューを経てからマージすることを推奨
    - revertは履歴を保持するため、force pushは行わない
    - 指定したコミット以降のすべての変更が取り消される


## `deploy-firebase-hosting.yml`
- Deep Link・パスキー設定用の`assetlinks.json`をFirebase Hostingに自動デプロイし、同じ署名鍵をSupabaseのRelying Party Originsへ同期します。

??? info "詳細（トリガー・処理内容・Secrets）"

    **トリガー条件:**

    - mainブランチへのプッシュ時
    - 対象パス: `public/.well-known/assetlinks.json`, `firebase.json`, `scripts/sync-rp-origins.sh`, 自ワークフロー
    - 手動実行（`workflow_dispatch`）。`assetlinks.json`を変えずにSupabase側だけ再同期したいときに使う

    **主な処理内容:**

    1. Firebase Hostingへのデプロイ（`assetlinks.json`の反映）
    2. `scripts/sync-rp-origins.sh --apply` によるSupabaseのRelying Party Origins同期

    **必要なGitHub Secrets:**

    - `FIREBASE_HOSTING_DEPLOY_SERVICE_ACCOUNT_JSON`
    - `FIREBASE_HOSTING_DOMAIN`, `SUPABASE_URL`, `SUPABASE_ACCESS_TOKEN`（同期ステップ用）

    !!! warning "二重管理の同期"

        - `assetlinks.json`（16 進）と、Supabase の Relying Party Origins（`android:apk-key-hash:`）は、同じ署名鍵を別形式で持っている。
        - 片方だけ更新すると、400 `webauthn_verification_failed` または `DomainNotAssociatedException` になる。エラーメッセージから原因を推測しにくい。
        - このワークフローが、両方をまとめて更新する。
        - `SUPABASE_ACCESS_TOKEN` が未登録の場合は、警告を出して、反映すべき値をログに表示するだけでスキップする。
        - 詳細は [Android 署名鍵の管理](android-signing-keys.md) を参照。


## `test.yml`
- PR・mainへのpushで回す、デバイス不要の単体/Widgetテストです。
- 配布用の`app.yml`とは切り離してある。

??? info "詳細（トリガー・処理内容・Secrets）"

    **トリガー条件:**

    - mainへのpush、PR、手動実行
    - 対象パス: `lib/` `test/` `integration_test/` `server/` `tool/` `scripts/` `pubspec.yaml` `pubspec.lock` `analysis_options.yaml` `dart_test.yaml` `.fvm/` `.fvmrc` 自ワークフロー

    **主な処理内容:**

    1. `pubspec.yaml`の`environment.flutter`を基準にFlutterバージョンを決め、FVMの固定値（`.fvmrc`）と食い違えば失敗させてからSDKをセットアップ（Issue #947）
    2. `.env`と統合テスト用設定の生成、`flutter pub get`、`build_runner`
    3. `dart analyze --no-fatal-warnings`（静的解析）
    4. `scripts/run-tests.sh`（単体/Widgetテスト）
    5. `server/order_assistant`のテスト（`dart test`）
    6. テスト結果をジョブサマリーに出力し、レポートをArtifactsへアップロード

    **必要なGitHub Secrets:**

    - `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `STARBUCKS_WEB_URL`, `GOOGLE_CLIENT_ID`, `GOOGLE_WEB_SERVER_CLIENT_ID`, `FIREBASE_HOSTING_DOMAIN`, `SSL_SHA256_FINGER_PRINT`


## `integration-test.yml`
- Androidエミュレータ上で`integration_test/`を実行します。
- 実Firebase/Supabaseに接続して遅く、バックエンドの状態に左右されるため、PRでは回さずnightlyと手動に限定している。

??? info "詳細（トリガー・処理内容・Secrets）"

    **トリガー条件:**

    - 毎日 03:00 JST（cron `0 18 * * *` = 18:00 UTC）
    - 手動実行（`workflow_dispatch`）

    **主な処理内容:**

    1. Flutter/Javaのセットアップ、`.env`・`google-services.json`・`secrets.properties`・統合テスト用設定の復元
    2. KVMを有効化し、`android-emulator-runner`でテストを実行（タイムアウト60分）
    3. テスト結果をジョブサマリーに出力し、レポートをArtifactsへアップロード

    - 進行中の実行は、打ち切らない（`cancel-in-progress: false`）。
    - APK のビルドも配布も行わない。

    **必要なGitHub Secrets:**

    - `test.yml`と同じ接続情報、`GOOGLE_SERVICES_JSON`, `MAPS_API_KEY`, `FIREBASE_APP_ID`
    - テスト用アカウント: `TEST_USER_EMAIL`, `TEST_USER_PASSWORD`, `TEST_USER_WRONG_PASSWORD`


## `deploy-edge-functions.yml`
- Supabase Edge Functionsを型チェックし、mainへのpushでデプロイします（Issue #943）。

??? info "詳細（トリガー・処理内容・Secrets）"

    **トリガー条件:**

    - mainへのpush、PR、手動実行
    - 対象パス: `supabase_schema/supabase/functions/**`, `supabase_schema/supabase/config.toml`, 自ワークフロー

    **主な処理内容:**

    1. `check`ジョブ: Edge Functionsの型チェック（PRでも実行）
    2. `deploy`ジョブ（PR以外）:
        - 必須Secretsの存在確認
        - デプロイ対象の決定（変更された関数のみ。`config.toml`が変わったとき、および手動実行は全関数）
        - Edge Functionのsecretを GitHub Secrets から同期
        - デプロイ（`--no-verify-jwt`は使わない。`verify_jwt`は`config.toml`を唯一の正とする）

    !!! warning "secretはGitHub Secretsを正とする"

        - Dashboard での手貼りや、手元のシェルからの `secrets set` は使わない。
        - PowerShell / cmd では JSON の二重引用符が壊れ、`pushNotify` がモジュール初期化時に停止した実績がある。

    **必要なGitHub Secrets:**

    - `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT`
    - 関数のsecret同期用: `RESEND_API_KEY`, `TEST_MAIL_ADDRESS`, `HOSTING_DOMEIN`, `ANTHROPIC_API_KEY`, `ORDER_ASSISTANT_MODEL`, `EXPORT_ARCHIVE_SECRET`, `EXPORT_ARCHIVE_AUTH_MODE`


## `deploy-firebase-functions.yml`
- CrashlyticsのアラートをGitHub Issueに変換するCloud Functionsをデプロイします。

??? info "詳細（トリガー・処理内容・Secrets）"

    **トリガー条件:**

    - mainへのpush、PR、手動実行
    - 対象パス: `functions/**`, `firebase.json`, 自ワークフロー

    **主な処理内容:**

    1. `build`ジョブ（PRでも実行）: `npm ci`、型チェック、ビルド、テスト
    2. `deploy`ジョブ（PR以外）: Firebase CLIとサービスアカウントを用意し、`firebase deploy --only functions`

    **事前設定（一度きり）:**

    - FirebaseプロジェクトをBlazeプランにする
    - Issue作成権限を持つGitHubトークンをSecret Managerに`GH_ISSUE_TOKEN`として登録する。`GITHUB_TOKEN`は使えない（Actionsのトークンで作ったIssueは他のワークフローを起動せず、[`claude.yml`](#claudeyml)の自動修復が発火しない）
    - Crashlyticsのアラートを有効にする

    **必要なGitHub Secrets:**

    - `FIREBASE_FUNCTIONS_DEPLOY_SERVICE_ACCOUNT_JSON`（Hosting用とは別の、Cloud Functionsのデプロイ権限を持つサービスアカウント）


## `deploy-order-assistant.yml`
- 会話注文の発話解釈サーバー（`server/order_assistant`）をCloud Runにソースデプロイします（Issue #998）。

??? info "詳細（トリガー・処理内容・Secrets）"

    **トリガー条件:**

    - mainへのpush、PR、手動実行
    - 対象パス: `server/order_assistant/**`, 自ワークフロー

    **主な処理内容:**

    1. `test`ジョブ（PRでも実行）: `dart format`、`dart analyze`、`dart test`
    2. `deploy`ジョブ（PR以外）: Google Cloud認証 → `Dockerfile`をCloud Buildでビルドして`order-assistant`サービスへデプロイ（リージョン`asia-northeast1`）→ サービスURLを表示

    **公開範囲:**

    - Cloud Run の IAM 認証は使わない（`--allow-unauthenticated`）。
    - サーバー側で、Supabase のアクセストークンを検証する。

    **必要なGitHub Secrets:**

    - `ORDER_ASSISTANT_DEPLOY_SERVICE_ACCOUNT_JSON`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`
    - Gemini APIキーはGitHub Secretsではなく、Google Cloud Secret Manager（`order-assistant-gemini-api-key`）に登録する

    **サーバーの任意の環境変数（ローカル確認用）:**

    | 名前 | 既定 | 内容 |
    |---|---|---|
    | `RATE_LIMIT_MAX` | `20` | 利用者ごとの1分あたりの上限回数。1以上の整数のみ有効で、0・負数・数値以外は既定値に戻る |

    - このワークフローでは設定しない。本番（Cloud Run）は常に既定の20回で動く
    - 上限超過（429）の確認で Gemini の呼び出しを減らすためだけに、ローカルで小さくする（例: `3`）。`server/order_assistant/.env` に書くか、起動時に渡す
    - `tool/check_server.sh --rate-limit` はサーバーと**同じ値**の `RATE_LIMIT_MAX` を必須とする（未設定だと失敗する）。有効な発話で最大 `RATE_LIMIT_MAX + 1` 回呼び、429 が出た時点で止める

    ```bash
    # サーバー側
    RATE_LIMIT_MAX=3 dart run bin/server.dart
    # 確認側（別ターミナル）
    RATE_LIMIT_MAX=3 bash tool/check_server.sh --rate-limit
    ```


## `schema-docs.yml`
- マイグレーションが変わったのにテーブル定義書・ER図が更新されていないPRを失敗させます。

??? info "詳細（トリガー・処理内容・Secrets）"

    **トリガー条件:**

    - PR、手動実行
    - 対象パス: `supabase_schema/supabase/migrations/**`, `supabase_table_definitions.md`, `entity_relationship/**`, `supabase_schema/scripts/**`, `supabase_schema/package.json`

    **主な処理内容:**

    1. Supabase（DBのみ）をローカルで起動
    2. `npm run schema:docs:check`で生成物が最新か検査
    3. `npm run schema:docs:svg`でER図を描画し、Artifactsへアップロード
    4. Supabaseを停止

    - 生成物そのものは、開発者が `npm run schema:docs` で作ってコミットする。
    - このワークフローは、検査のみ行う。


## `design-tokens.yml`
- `design/tokens.json`または生成スクリプトを変えたPRで、`lib/constants/design_tokens.g.dart`を再生成します（Issue #1003）。

??? info "詳細（トリガー・処理内容・Secrets）"

    **トリガー条件:**

    - PR（対象パス: `design/tokens.json`, `tool/gen_design_tokens.dart`, `tool/src/design_tokens_generator.dart`, 自ワークフロー）
    - 手動実行

    **主な処理内容:**

    1. `dart tool/gen_design_tokens.dart`で再生成
    2. 同一リポジトリのPR: 差分があればPRブランチへ自動コミット
    3. フォークのPR・手動実行: 書き込まずに、生成物が最新かだけ検査（古ければ失敗）

    !!! note "自動コミットではTestが起動しない"

        - `GITHUB_TOKEN` で push したコミットは、他のワークフローを起動しない。
        - 自動コミットが入ったら、`test.yml` を Actions 画面から手動実行するか、もう 1 回 push する。


## `docs.yml`
- `docs/zensical/`のドキュメントサイトをビルドし、GitHub Pagesに公開します。

??? info "詳細（トリガー・処理内容・Secrets）"

    **トリガー条件:**

    - mainへのpush（対象パス: `docs/zensical/**`）
    - 手動実行

    **主な処理内容:**

    1. `pip install zensical` → `zensical build --clean`（`docs/zensical`で実行）
    2. `docs/zensical/site`をPagesへアップロードしてデプロイ


## `documentation-sync.yaml`
- `lib/screens/`・`lib/services/`のDartファイルを変えたPRで、対応するドキュメントをClaudeに作成・更新させます。

??? info "詳細（トリガー・処理内容・Secrets）"

    **トリガー条件:**

    - PR（対象パス: `lib/screens/**/*.dart`, `lib/services/**/*.dart`）

    **主な処理内容:**

    1. ベースブランチとの差分から対象ファイルを抽出
    2. `anthropics/claude-code-base-action`で変更内容を分析（最大3ターン）し、更新すべきdocsを判断
    3. 同アクションでドキュメントを生成・更新
    4. 変更があればgithub-actions botとしてPRブランチへコミット

    **必要なGitHub Secrets:**

    - `ANTHROPIC_API_KEY`


## 参考資料
- [CI/CDパイプラインを作成](https://zenn.dev/takuowake/articles/e1f52c5f0fb4ab)
- [App Distribution部分の詳細](https://atsum.in/android/app-distribution-github-actions/#google_vignette)
- [SAに付与する権限](https://github.com/wzieba/Firebase-Distribution-Github-Action/wiki/FIREBASE_TOKEN-migration)
- [ロールを探すときのTips（roles/firebaseappdistro.adminを検索ワードにする）](https://stackoverflow.com/questions/75427162/firebase-app-distribution-admin-role-is-missing)
