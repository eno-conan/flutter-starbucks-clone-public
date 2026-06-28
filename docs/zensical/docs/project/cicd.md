# CI/CD - GitHub Actions

## ワークフローファイル一覧

本プロジェクトでは以下のGitHub Actionsワークフローを使用しています。

| ワークフロー名 | ファイル名 | トリガー | 用途 |
|--------------|-----------|---------|------|
| Flutter CI/CD | [`app.yml`](#appyml) | mainへのpush/PR | ビルド・テスト・デプロイの自動化 |
| Claude Support | [`claude.yml`](#claudeyml) | `@claude`メンション | Issue/PRでのAI支援 |
| AI Code Review | [`claude-code-review.yml`](#claude-code-reviewyml) | PRのオープン/更新 | 自動コードレビュー |
| Bot PR Review | [`claude-code-review-only-bot.yml`](#claude-code-review-only-botyml) | ボットによるPR | ボットPRの自動レビュー |
| Revert Commit | [`revert-to-commit.yml`](#revert-to-commityml) | 手動実行 | 特定コミットへの巻き戻し |
| Firebase Deploy | [`deploy-firebase-hosting.yml`](#deploy-firebase-hostingyml) | mainへのpush | assetlinks.jsonのデプロイ |
| Flutter Version Update | [`flutter-update-latest.yml`](#flutter-update-latestyml) | 水曜日の午前7時 | Flutterの最新安定版への自動更新 |
| Dependabot 自動マージ | [`dependabot-auto-merge.yml`](#dependabot-auto-mergeyml) | 水曜日の午後5時 | Dependabotパッチバージョンの自動マージ |

## `app.yml`
Flutter アプリケーションのビルド、テスト、デプロイを自動化します。

<details>
<summary>詳細を見る</summary>

**トリガー条件:**
- mainブランチへのプッシュ時
- mainブランチへのPR作成・更新時
- 対象パス: `.github/**`, `android/**`, `lib/**`, `test/**`, `integration_test/**`, `pubspec.yaml`

**主な処理内容:**
1. **環境セットアップ**
    - Flutter 3.44.2のインストール
    - Android SDKのセットアップ
    - 各種キャッシュの復元（依存関係、Gradle、Android SDK）

2. **シークレット情報の復元**
    - `google-services.json`の復元（Base64デコード）
    - リリース用Keystoreファイルの作成
    - `key.properties`の生成（署名情報）
    - `secrets.properties`の生成（Maps API Key等）
    - `.env`ファイルの生成（Supabase、Firebase等の接続情報）

3. **ビルドプロセス**
    - `build_runner`の実行（コード生成）
    - 静的解析（`flutter analyze --no-fatal-infos`）
    - テストの実行（`flutter test`）
    - APKのビルド（ABI別、難読化あり）

4. **後処理**
    - ビルド成果物のクリーンアップ
    - （コメントアウト済）Firebase App Distributionへのデプロイ

**必要なGitHub Secrets:**
- 認証情報: `GOOGLE_SERVICES_JSON`, `RELEASE_KEYSTORE`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`
- API Keys: `MAPS_API_KEY`, `ANTHROPIC_API_KEY`
- Firebase: `FIREBASE_APP_ID`, `FIREBASE_HOSTING_DOMAIN`, `CREDENTIAL_FILE_CONTENT`
- Supabase: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- Google認証: `GOOGLE_CLIENT_ID`, `GOOGLE_WEB_SERVER_CLIENT_ID`
- その他: `STARBUCKS_WEB_URL`, `SSL_SHA256_FINGER_PRINT`, `PUBLISHABLE_KEY`, `SECRET_KEY`

</details>

## `claude.yml`
IssueやPRのコメントで`@claude`とメンションすることで、Claudeによる支援を受けられます。

<details>
<summary>詳細を見る</summary>

**トリガー条件:**
- Issueコメントに`@claude`が含まれる時
- PRレビューコメントに`@claude`が含まれる時
- PRレビュー本文に`@claude`が含まれる時
- Issueのタイトル・本文に`@claude`が含まれる時

**主な処理内容:**
- Claude Code Actionの実行（最大8ターン、Bashツール使用可能）
- モデル: `claude-4-0-sonnet-20250805`

**必要なGitHub Secrets:**
- `ANTHROPIC_API_KEY`

</details>

## `claude-code-review.yml`
PRの差分を自動的にレビューし、改善提案をコメントします。

<details>
<summary>詳細を見る</summary>

**トリガー条件:**
- PRのオープン・同期・再オープン時

**主な処理内容:**
- 変更ファイルの差分解析
- Claudeによるコードレビュー
- レビューコメントの自動投稿

</details>

## `claude-code-review-only-bot.yml`
ボット（Dependabot等）によるPRに対して、Claudeによるレビューを実行します。

<details>
<summary>詳細を見る</summary>

**トリガー条件:**
- ボットアカウントによるPRのオープン・同期時

**主な処理内容:**
- claude-code-review.ymlと同様のレビュープロセス

</details>

## `revert-to-commit.yml`
mainブランチの特定のコミットまで状態を戻すためのワークフローです。

<details>
<summary>詳細を見る</summary>

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

</details>

## `deploy-firebase-hosting.yml`
Deep Link設定用の`assetlinks.json`をFirebase Hostingに自動デプロイします。

<details>
<summary>詳細を見る</summary>

**トリガー条件:**
- mainブランチへのプッシュ時
- `public/.well-known/assetlinks.json`の変更がある場合

**主な処理内容:**
- `assetlinks.json`の更新
- Firebase Hostingへの自動デプロイ

**必要なGitHub Secrets:**
- `FIREBASE_HOSTING_DEPLOY_SERVICE_ACCOUNT_JSON`

</details>

## `flutter-update-latest.yml`
Flutterの最新安定版への自動更新を実装します。

<details>
<summary>詳細を見る</summary>

**トリガー条件:**
- 水曜日の午前7時

**主な処理内容:**
- Flutterの最新安定版を取得
- 現在のFlutterバージョンを確認
- 更新が必要な場合、自動的にPRを作成して更新を提案

**必要なGitHub Secrets:**
- `GITHUB_TOKEN`

</details>

## `dependabot-auto-merge.yml`
Dependabotが作成したパッチバージョンアップPRを、CI通過を条件に自動マージします。

<details>
<summary>詳細を見る</summary>

**トリガー条件:**
- 毎週水曜日 17:00 JST（= 08:00 UTC）
- 手動実行（`workflow_dispatch`）

**主な処理内容:**
1. DependabotのオープンなパッチバージョンアップPRを一覧取得
2. 各PRに対して以下を確認
    - CI チェックが全て `SUCCESS` であること
    - パッチバージョンアップであること（メジャー・マイナーは対象外）
3. 条件を満たしたPRを `gh pr merge --merge` で自動マージ

**バージョン判定ロジック:**
- **シングルパッケージ**: タイトル `Bump X from A.B.C to D.E.F` をパース
    - メジャー・マイナーが同じ場合のみパッチと判定
- **グループPR**: タイトル `Bump the X group` → PRボディのバージョンテーブルを解析
    - グループ内の全パッケージがパッチの場合のみマージ

**スキップ条件:**
- CIチェックが未実行または未通過
- マイナー・メジャーバージョンアップ
- バージョン情報が解析不可能なタイトル

**必要な権限:**
- `contents: write` - マージコミットの作成
- `pull-requests: write` - PRのマージ操作

**動作フロー:**
```
水曜 7:00 JST  Dependabot が PR 作成
水曜 7〜9時    claude-code-review-only-bot.yml が実行（flutter test + Claudeレビュー）
水曜 17:00 JST dependabot-auto-merge.yml が実行
               ├─ CI通過 + パッチ → 自動マージ
               ├─ CI通過 + マイナー/メジャー → スキップ（手動マージ）
               └─ CI未通過 → スキップ
```

</details>

## 参考資料
- [CI/CDパイプラインを作成](https://zenn.dev/takuowake/articles/e1f52c5f0fb4ab)
- [App Distribution部分の詳細](https://atsum.in/android/app-distribution-github-actions/#google_vignette)
- [SAに付与する権限](https://github.com/wzieba/Firebase-Distribution-Github-Action/wiki/FIREBASE_TOKEN-migration)
- [ロールを探すときのTips（roles/firebaseappdistro.adminを検索ワードにする）](https://stackoverflow.com/questions/75427162/firebase-app-distribution-admin-role-is-missing)
