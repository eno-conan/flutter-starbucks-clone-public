# Google Cloud セキュリティガイドライン

## 概要

本ドキュメントは、Google Cloud Platform（GCP）の認証情報を安全に管理するためのガイドラインです。
Maps API Key を中心に、以下の 3 点について手順を示します。

1. **Secret Manager による認証情報管理**（CI ビルド時注入）
2. **バンドルID（パッケージ名 + SHA-1）による API キー制限**
3. **キーローテーション構成**

---

## 現状

| 項目 | 現状 |
|---|---|
| APIキー保管 | GitHub Secrets（`MAPS_API_KEY`）|
| ビルド時注入 | `app.yml` → `secrets.properties` → Secrets Gradle Plugin |
| バンドルID制限 | 設定済み（パッケージ名 + SHA-1 による制限を実施済み）|
| キーローテーション | 手動（同じキーを使い続けている）|

---

## 1. Secret Manager による認証情報管理

### 目的

GitHub Secrets に直接保管していた API キーを GCP Secret Manager へ移行し、
アクセスログの記録・IAM による細かいアクセス制御・自動ローテーション連携を可能にする。

### アーキテクチャ

```
現状:
GitHub Secrets (MAPS_API_KEY) → app.yml → secrets.properties → APK

目標:
GCP Secret Manager (MAPS_API_KEY) ← CI サービスアカウント
                                  → app.yml → secrets.properties → APK
```

> **注意**: モバイルアプリから直接 Secret Manager を呼ぶ場合、
> サービスアカウント鍵を APK に埋め込む本末転倒な問題が生じる。
> そのため **CI パイプライン経由のビルド時注入**を採用する。

### 実装手順

#### 1. GCP コンソールで Secret Manager を有効化

```
GCP コンソール → APIs & Services → Enable APIs and Services
→ "Secret Manager API" を検索して有効化
```

#### 2. シークレットを作成

```bash
# gcloud CLI を使う場合
gcloud secrets create MAPS_API_KEY \
  --replication-policy="automatic" \
  --project=<PROJECT_ID>

# 初期値を登録（現在の API キー値）
echo -n "<YOUR_MAPS_API_KEY>" | gcloud secrets versions add MAPS_API_KEY \
  --data-file=- \
  --project=<PROJECT_ID>
```

#### 3. CI 専用サービスアカウントを作成

```bash
gcloud iam service-accounts create ci-builder \
  --display-name="CI Builder" \
  --project=<PROJECT_ID>

# Secret Manager 閲覧権限を付与
gcloud secrets add-iam-policy-binding MAPS_API_KEY \
  --member="serviceAccount:ci-builder@<PROJECT_ID>.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=<PROJECT_ID>
```

#### 4. サービスアカウントキーを GitHub Secret に登録

```bash
# サービスアカウントキー（JSON）を生成
gcloud iam service-accounts keys create ci-sa-key.json \
  --iam-account=ci-builder@<PROJECT_ID>.iam.gserviceaccount.com

# ※ ci-sa-key.json の内容を GitHub Secret「GCP_SA_KEY」として登録
# GitHub リポジトリ → Settings → Secrets and variables → Actions → New secret
```

#### 5. `app.yml` を修正

```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    credentials_json: ${{ secrets.GCP_SA_KEY }}

- name: Fetch Maps API Key from Secret Manager
  id: secrets
  uses: google-github-actions/get-secretmanager-secrets@v2
  with:
    secrets: |-
      MAPS_API_KEY:projects/<PROJECT_ID>/secrets/MAPS_API_KEY/versions/latest

- name: Create secrets.properties
  run: |
    echo "MAPS_API_KEY=${{ steps.secrets.outputs.MAPS_API_KEY }}" >> android/secrets.properties
    echo "FIREBASE_APP_ID=${{ secrets.FIREBASE_APP_ID }}" >> android/secrets.properties
    echo "FIREBASE_HOSTING_DOMAIN=${{ secrets.FIREBASE_HOSTING_DOMAIN }}" >> android/secrets.properties
```

### メリット

- アクセスログ（誰がいつキーを取得したか）が GCP に記録される
- ローテーション後も CI は常に `versions/latest` を取得するため修正不要
- Secret Manager の IAM で細かいアクセス制御が可能

---

## 2. バンドルID（パッケージ名 + SHA-1）による API キー制限

### 目的

Maps API Key を特定のアプリ（パッケージ名 + 署名証明書）からのみ使用可能に制限し、
キーが漏洩しても第三者に悪用されないようにする。

### 設定場所

```
GCP コンソール → APIs & Services → Credentials
→ Maps API Key をクリック → Edit API key
```

### SHA-1 フィンガープリントの取得

#### デバッグ証明書（開発用）

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android
```

#### リリース証明書（本番用）

```bash
keytool -list -v \
  -keystore <path-to-release.keystore> \
  -alias <KEY_ALIAS> \
  -storepass <KEYSTORE_PASSWORD>
```

### GCP コンソールでの設定手順

1. **Application restrictions** を `Android apps` に変更
2. **Add an item** で以下の組み合わせを追加

| 環境 | Package Name | Fingerprint |
|---|---|---|
| Debug | com.example.testingapp | デバッグ証明書 SHA-1 |
| Release | com.example.testingapp | リリース証明書 SHA-1 |

3. **API restrictions** も設定：`Maps SDK for Android` のみに絞る

```
API restrictions → Restrict key → Maps SDK for Android にチェック
```

4. **Save** をクリック

### 注意点

- CI でビルドする場合は CI 環境の署名 SHA-1 も追加が必要
- バンドルID制限と Secret Manager は独立して設定可能（並行実施 OK）
- 制限変更後は反映まで数分かかる場合がある

---

## 3. キーローテーション構成

### 目的

API キーを定期的に更新することで、漏洩リスクを最小限に抑える。
Secret Manager を使った自動ローテーションを構成する。

### 推奨ローテーション周期

- **通常運用**: 90 日以内（GCP Security 推奨）
- **本番リリース前後**: 手動ローテーションを実施

### 自動ローテーションのアーキテクチャ

```
Cloud Scheduler（定期実行: 例 90 日ごと）
  ↓
Pub/Sub トピック（rotation-trigger）
  ↓
Cloud Functions（rotate-maps-api-key）
  ↓
  1. Google Maps Platform API で新しい API キーを作成
  2. Secret Manager に新バージョンとして登録
  3. 旧バージョンを無効化（DISABLED 状態へ）
  4. 通知送信（メール / Slack）
```

### Cloud Functions の処理フロー（疑似コード）

```python
def rotate_maps_api_key(event, context):
    # 1. Maps API キーを新規作成
    new_key = maps_client.create_api_key(project=PROJECT_ID)

    # 2. Secret Manager に新バージョンとして追加
    secret_client.add_secret_version(
        parent=f"projects/{PROJECT_ID}/secrets/MAPS_API_KEY",
        payload={"data": new_key.key_string.encode()}
    )

    # 3. 旧バージョン（latest-1）を無効化
    secret_client.disable_secret_version(
        name=f"projects/{PROJECT_ID}/secrets/MAPS_API_KEY/versions/<OLD_VERSION>"
    )

    # 4. 通知
    notify_slack(f"Maps API Key rotated. New version created.")
```

### CI との連携

- CI は常に `versions/latest` を参照するため、ローテーション後も変更不要
- ローテーション完了後の次回 CI ビルドで自動的に新しいキーが使用される

### Cloud Scheduler の設定

```bash
# Pub/Sub トピックを作成
gcloud pubsub topics create rotation-trigger --project=<PROJECT_ID>

# Cloud Scheduler ジョブを作成（90 日ごと）
gcloud scheduler jobs create pubsub rotate-maps-api-key-job \
  --schedule="0 0 1 */3 *" \
  --topic=rotation-trigger \
  --message-body='{"action":"rotate","secret":"MAPS_API_KEY"}' \
  --project=<PROJECT_ID>
```

---

## セキュリティチェックリスト

### リリース前

- [ ] Secret Manager に API キーが登録されている
- [ ] CI サービスアカウントに `roles/secretmanager.secretAccessor` が付与されている
- [ ] `app.yml` が `versions/latest` を参照している
- [ ] GCP コンソールで Maps API Key に Android アプリ制限が設定されている
- [ ] パッケージ名（Debug / Release 両方）が登録されている
- [ ] SHA-1 フィンガープリント（Debug / Release 両方）が登録されている
- [ ] API restrictions で `Maps SDK for Android` のみに絞られている

### 定期見直し

- [ ] キーのローテーションが 90 日以内に実施されているか
- [ ] GCP の Secret Manager アクセスログに不審なアクセスがないか
- [ ] CI サービスアカウントの権限が最小限になっているか
- [ ] 不要になった古いシークレットバージョンが無効化されているか

---

## 参考資料

- [GCP Secret Manager ドキュメント](https://cloud.google.com/secret-manager/docs)
- [google-github-actions/get-secretmanager-secrets](https://github.com/google-github-actions/get-secretmanager-secrets)
- [Maps API キーのセキュリティ](https://developers.google.com/maps/api-security-best-practices)
- [GCP セキュリティベストプラクティス](https://cloud.google.com/security/best-practices)
- 関連 Issue: #626
