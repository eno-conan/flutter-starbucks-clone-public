# Android 署名鍵の管理

Android の署名鍵は **利用者ごとではなく配布経路ごと**に変わる。パスキー（WebAuthn）と App Links は
どちらも「このドメインはこの署名鍵のアプリを信頼する」という宣言に依存しているため、
配布経路を増やすたびに鍵の登録が必要になる。

関連: [Issue #924](https://github.com/eno-conan/flutter-starbucks-clone/issues/924) /
[パスキー導入設計](../starbucks_user_side/signin/passkey-design.md)

---

## 1. 配布経路ごとの有効な鍵

| 経路 | ユーザー端末で有効な鍵 | 誰が持つか |
|---|---|---|
| `flutter run` / デバッグビルド | `android/debug.keystore`（未配置なら各自の `~/.android/debug.keystore`） | チームで共有（リポジトリ外・案A）。未配置だと**開発者ごとに異なる**唯一の経路になる |
| ローカル release ビルド | `android/key.properties` が指す keystore | チームで共有（リポジトリ外） |
| CI の release ビルド | `secrets.RELEASE_KEYSTORE` | CI |
| Firebase App Distribution | **アップロードした成果物の署名そのまま**（再署名なし） | 上と同じ |
| Google Play（Play App Signing 有効） | **Google が再署名した app signing key** | Google |

### 最も事故りやすい点: Play App Signing

```
開発者: upload key で署名した AAB をアップロード
   ↓
Google: upload key を検証 → 剥がす → app signing key で再署名
   ↓
ユーザー: app signing key で署名された APK を受け取る
```

**登録すべきは app signing key の SHA-256 であって upload key ではない。**
取り違えると「手元の release ビルドでは動くが Play 経由だと動かない」という切り分けの難しい事故になる。

確認場所: Play Console → テストとリリース → 設定 → アプリの署名
（「アプリ署名鍵の証明書」と「アップロード鍵の証明書」の SHA-256 が両方表示される）

---

## 2. `assetlinks.json` に登録している鍵

`public/.well-known/assetlinks.json` は 2 つの relation を持ち、**それぞれ別の鍵集合を持てる**。

| relation | 用途 | 未登録時の症状 |
|---|---|---|
| `delegate_permission/common.handle_all_urls` | App Links（Deep Link） | リンクがブラウザで開く |
| `delegate_permission/common.get_login_creds` | パスキー（Credential Manager） | `DomainNotAssociatedException` |

現在登録している鍵:

| SHA-256（先頭） | 何の鍵か | 備考 |
|---|---|---|
| `43:F2:CF:97:…` | **release 鍵** | `android/key.properties` / CI の `secrets.RELEASE_KEYSTORE`。`handle_all_urls` / `get_login_creds` 両方に登録 |
| `B6:26:8F:61:…` | **共有 debug 鍵** | `android/debug.keystore`。チーム共通（案A）。両方に登録 |
| ~~`78:80:C0:87:…`~~ | 個人の debug 鍵 | 案A への移行で両 relation から削除済み |
| ~~`DA:BA:6E:3A:…`~~ | 使われていない鍵 | Issue #924 で両 relation から削除済み |

登録内容を確認・突き合わせるコマンド:

```bash
# 共有 debug 鍵
keytool -list -v -keystore android/debug.keystore -alias androiddebugkey -storepass android

# release 鍵（android/key.properties の storeFile / keyAlias を参照）
keytool -list -v -keystore <storeFile> -alias <keyAlias>
```

CI がビルドした APK の署名鍵は、`app.yml` の **Verify APK signing certificate** ステップが
毎回ログに出す。`assetlinks.json` に未登録なら警告が出る。

### 開発者ごとの debug キーの扱い: **案A（チーム共通の debug keystore）を採用**

Relying Party Origins は **上限 5 つ**で、`https://` に 1 つ使うため Android の鍵は最大 4 つ。
debug 鍵を開発者ごとに登録すると 2〜3 人目で枯渇するため、**チーム共通の debug keystore を 1 本**用意し、
それだけを登録する方針にした（Issue #924 4-1）。検討した代案は、開発用に別の Supabase プロジェクトを
立てる案（環境分離としては健全だが運用コストが増える）。

現在の使用状況は次のコマンドで確認できる。案A なら開発者が増えても **3/5 のまま**増えない。

```bash
FIREBASE_HOSTING_DOMAIN=<裸ドメイン> bash scripts/sync-rp-origins.sh
```

#### 開発者のセットアップ

1. Google ドライブの共有ディレクトリから `debug.keystore` を取得する（配置場所は口頭・チャットで共有）
2. リポジトリの `android/debug.keystore` に置く（`android/.gitignore` の `**/*.keystore` で除外済み。コミットしない）
3. 取得したファイルが正しいか照合する

```bash
keytool -list -v -keystore android/debug.keystore -alias androiddebugkey -storepass android
# SHA-256 が B6:26:8F:61:B8:89:CD:EC:4C:25:6A:41:9C:88:4A:40:E6:BC:67:13:D2:9C:F3:8F:FC:D1:16:1F:F5:79:33:06 であること
```

!!! tip "照合を飛ばさない"

    この運用で実際に起きるのは鍵の盗難より「古いファイルを掴んでいて気づかない」で、
    症状は 400 `webauthn_verification_failed` という原因の分かりにくいエラーになる。
    上の SHA-256 と一致するかを最初に見れば数十秒で切り分けられる。

`android/app/build.gradle` の `signingConfigs.debug` は、このファイルが**無ければ各自の
`~/.android/debug.keystore` にフォールバックする**。未配置でも `flutter run` は通り、
パスキーだけが動かない状態になる（ビルドが落ちて原因が分からない、を避けるため）。

#### 個人の debug 鍵から移行するときの後始末

- 端末にある既存の debug ビルドは署名が変わるため上書きできない（`INSTALL_FAILED_UPDATE_INCOMPATIBLE`）。
  一度アンインストールする
- **旧 debug 鍵で登録したパスキーは使えなくなる**（オリジンが変わるため）。debug 環境で作った
  パスキーは登録し直す

#### 鍵を差し替えるときに更新する場所

共有 debug keystore を作り直す・release 鍵を差し替える場合は、SHA が **3 箇所**に登録されている点に注意する。
`assetlinks.json` だけ直すと Maps と Firebase が壊れる。

| 登録先 | 形式 | 未更新時の症状 |
|---|---|---|
| `public/.well-known/assetlinks.json` | SHA-256 | パスキー・App Links が動かない |
| Firebase の Android アプリ | SHA-1 / SHA-256 | FCM・Firebase 認証まわりが動かない。`google-services.json` の再取得と `GOOGLE_SERVICES_JSON` シークレット更新も必要 |
| Google Cloud の `MAPS_API_KEY` 制限 | SHA-1 | 地図が真っ白になる（[Google Cloud セキュリティ](google-cloud-security-guidelines.md)参照） |

---

## 3. 二重管理の同期（`scripts/sync-rp-origins.sh`）

同じ鍵の情報を 2 箇所に**別形式で**持っている。

| 場所 | 形式 | 用途 |
|---|---|---|
| `public/.well-known/assetlinks.json` | `43:F2:CF:…`（16進・コロン区切り） | Digital Asset Links。OS がアプリとドメインの紐づけを検証する |
| Supabase の Relying Party Origins | `android:apk-key-hash:Q_LPl-8e…`（生 32 バイトの base64url） | WebAuthn のオリジン検証 |

片方だけ更新すると、エラーメッセージから原因を推測しにくい失敗になる。

| 更新漏れ | 症状 |
|---|---|
| RP Origins 未更新 | OS のセレモニーは成功するが、サーバ検証で 400 `webauthn_verification_failed` |
| assetlinks 未更新 | OS が `DomainNotAssociatedException` を投げ、認証情報の生成に到達しない |

### 自動反映

`main` へ `assetlinks.json` がマージされると `deploy-firebase-hosting.yml` が
**Firebase Hosting へのデプロイ → Supabase の RP Origins 更新**の順で実行する。手作業は不要。

Hosting デプロイの後に同期を置いているのは、同期に失敗しても Hosting のデプロイ自体は
完了させるため。ズレたまま残った場合は同ワークフローを **手動実行（`workflow_dispatch`）** すれば
`assetlinks.json` を変更しなくても再同期できる。

### 手動での確認・反映

```bash
# 変換結果を表示するだけ（ネットワーク不要。ダッシュボードへ貼る値の確認に使う）
FIREBASE_HOSTING_DOMAIN=<裸ドメイン> bash scripts/sync-rp-origins.sh

# Supabase の現在値と突き合わせる（差分があれば exit 1）
bash scripts/sync-rp-origins.sh --check

# Supabase へ反映する（差分がなければ何もしない）
bash scripts/sync-rp-origins.sh --apply
```

`--check` / `--apply` に必要な環境変数:

| 変数 | 説明 |
|---|---|
| `FIREBASE_HOSTING_DOMAIN` | 裸ドメイン。`https://<domain>` のオリジンに使う |
| `SUPABASE_ACCESS_TOKEN` | [Management API のアクセストークン](https://supabase.com/dashboard/account/tokens) |
| `SUPABASE_PROJECT_REF` | プロジェクト ref。未設定なら `SUPABASE_URL` から導出する |

スクリプトは `get_login_creds` の鍵だけを読み、オリジンが上限 5 つを超える場合は
反映せずに失敗する（黙って切り捨てるとどの鍵が落ちたか分からなくなるため）。

### GitHub Secrets

自動反映には `SUPABASE_ACCESS_TOKEN` の登録が必要。未登録の場合はワークフローが
**警告を出して反映すべき値をログに表示するだけ**でスキップするので、その値を
Supabase ダッシュボード（Authentication → Passkeys → Relying Party Origins）へ貼れば手動でも運用できる。

---

## 4. Firebase App Distribution での配布

`app.yml` を **手動実行（Actions → Flutter CI/CD Pipeline Starbucks Clone App → Run workflow）** する。

| 入力 | 既定 | 説明 |
|---|---|---|
| `run_tests` | true | `flutter test` を実行する |
| `build_apk` | true | APK をビルドする |
| `distribute` | true | App Distribution へ配布する |
| `release_notes` | 空 | 配布時のリリースノート。省略時はブランチ名とコミットハッシュ |

配布されるのは `app-arm64-v8a-release.apk`（`--split-per-abi` の arm64 版）。

### APK を GitHub Actions の Artifacts に置かない理由

APK は 1 ファイル約 40MB あり、毎回 Artifacts に上げると Free プランのストレージ上限に到達する。
成果物の受け渡しは Artifacts ではなく App Distribution に寄せているため、`app.yml` は
意図的に `Upload APK` ステップを持たない。手元に APK が必要なときはローカルでビルドすること。

### 鍵の観点での注意

App Distribution は**アップロードした成果物の署名をそのまま配る（再署名しない）**。
CI の `secrets.RELEASE_KEYSTORE` の鍵がそのままユーザー端末で有効な鍵になるため、
その SHA-256 が `assetlinks.json` の `get_login_creds` に入っていないとパスキーが動かない。
現在の release 鍵は `43:F2:CF:97:…` で登録済みのため、この経路の配布はそのまま動く。
CI の **Verify APK signing certificate** ステップがこれを毎回照合し、未登録なら警告を出す。

### 必要な GitHub Secrets

| Secret | 用途 |
|---|---|
| `FIREBASE_APP_ID` | 配布先アプリの App ID |
| `CREDENTIAL_FILE_CONTENT` | サービスアカウント JSON の中身。`roles/firebaseappdistro.admin` が必要 |

配布先グループは `testers`（Firebase コンソール → App Distribution → テスターとグループ）。

---

## 5. Play Store 導入時の手順

まだ導入していない。始める時点で以下を実施する。

1. Play Console で内部テストトラックにアプリを作成し、Play App Signing を有効にする
2. **app signing key の SHA-256** を Play Console（テストとリリース → 設定 → アプリの署名）から控える
   - upload key の SHA-256 ではない。ここを取り違えると Play 経由だけ動かなくなる
3. その SHA-256 を `public/.well-known/assetlinks.json` の **両方の relation** に追加する
4. `main` へマージする。`deploy-firebase-hosting.yml` が Hosting へ反映し、
   Supabase の RP Origins も自動で更新される
   - 上限 5 つに収まるか事前に `bash scripts/sync-rp-origins.sh` で確認する
5. Play 経由でインストールした実機でパスキー登録が通ることを確認する
6. `app.yml` の APK ビルドを AAB（`flutter build appbundle`）に切り替える
   - App Distribution 用の APK ビルドと併存させるか、入力で切り替えるかはその時点で決める

---

## 6. トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| 400 `webauthn_verification_failed` | RP Origins に該当の鍵が未登録 | `bash scripts/sync-rp-origins.sh --check` で差分を確認し `--apply` |
| `DomainNotAssociatedException` | `assetlinks.json` の `get_login_creds` に鍵が未登録、または Hosting 未反映 | 鍵を追加して `main` へマージ（Hosting と RP Origins が同時に更新される） |
| 手元の release ビルドは動くが Play 経由だと動かない | upload key を登録して app signing key を登録していない | Play Console の「アプリ署名鍵の証明書」の SHA-256 を登録する |
| Deep Link は動くがパスキーだけ動かない | `handle_all_urls` にはあるが `get_login_creds` にない | 両方の relation に同じ鍵を入れる |
| CI が「assetlinks.json に未登録」と警告する | CI の release 鍵が `assetlinks.json` にない | ログに出た SHA-256 を `get_login_creds` へ追加する |
