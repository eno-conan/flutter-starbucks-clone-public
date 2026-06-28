# Push通知アーキテクチャ

## 概要

注文が「提供済み」になったタイミングで、FCM（Firebase Cloud Messaging）経由でユーザーに Push 通知を送る仕組み。Supabase Database Webhook → Edge Function → FCM v1 API の流れで動作する。

---

## 全体フロー

```
[Flutter アプリ]
  ↓ ログイン成功 / アプリ起動（既存セッション）
  ↓ requestPermissionAfterLogin()
FCMトークン取得 → user_fcm_tokens テーブルへ upsert
  （デバイス単位: user_id + device_id の複合キー）

[スタッフ側]
  orders.provided_status を 0 → 1 に更新
  ↓
[Supabase Database Webhook]
  ↓ orders テーブルの UPDATE をトリガー
[Edge Function: pushNotify]
  ↓ user_fcm_tokens から is_notify=1 のデバイスを取得
  ↓ FCM v1 API に送信（全デバイス並列）
[ユーザーのデバイス]
  Push通知受信「受取番号:XX 商品のご用意ができました」
```

---

## FCMトークン登録フロー

FCMトークンは `user_fcm_tokens` テーブルに `upsert`（複合キー `user_id, device_id` で競合解決）される。

### 登録タイミング

| タイミング | 処理場所 | 詳細 |
|---|---|---|
| メール/パスワードログイン成功後 | `lib/screens/starbucks_user_side/signin/login.dart` | `_navigateToHome()` 内で `requestPermissionAfterLogin()` を呼ぶ |
| Google OAuth ログイン成功後 | `lib/app/app.dart` の `_handleOAuthCallback()` | `onAuthStateChange.signedIn` 待機後に `requestPermissionAfterLogin()` を呼ぶ |
| アプリ起動（既存セッション保持中） | `lib/app/app.dart` の `_initializeApp()` | セッションが存在すれば `unawaited` で `requestPermissionAfterLogin()` を呼ぶ |
| FCMトークンリフレッシュ時 | `lib/screens/starbucks_user_side/signin/login.dart` | `FirebaseMessaging.instance.onTokenRefresh` リスナー |

### 登録処理の呼び出しチェーン

```
requestPermissionAfterLogin()          ← NotificationPermissionService
  → _requestPermission()
    → FirebaseMessaging.instance.requestPermission()   // OS通知許可ダイアログ
    → FirebaseMessaging.instance.getToken()            // FCMトークン取得
    → authService.setFcmTokenAndNotifySetting()
      → UserFcmTokenRepository.upsertFcmToken()
        → supabase.from('user_fcm_tokens').upsert({...}, onConflict: 'user_id,device_id')
```

### 重要：Google OAuth ログインの特殊性

Google OAuth はブラウザ経由の認証のため、ログインフロー中ではなく、ディープリンクコールバック（`testingapp://callback`）で処理される。

```
ログイン画面 → ブラウザ（Google認証）→ testingapp://callback
  ↓ app.dart の _listenToDeepLinks / getInitialLink() が受信
  ↓ _handleOAuthCallback(uri)
    → supabase.auth.getSessionFromUrl(uri)
    → currentSession が null の場合 → onAuthStateChange.signedIn を最大5秒待機
    → セッション確立を確認後 → _navigateToHome() + requestPermissionAfterLogin()
```

> **なぜ待機が必要か**  
> Supabase Flutter が内部で非同期にセッションを確立するため、`getSessionFromUrl` 呼び出し直後は `currentSession` がまだ null になる競合状態が発生する。`onAuthStateChange.signedIn` を待機することで確実にセッション確立後に処理を行う。

---

## user_fcm_tokens テーブル

| カラム | 型 | 備考 |
|---|---|---|
| user_id | uuid | PK（複合）, auth.users への FK |
| device_id | text | PK（複合）, デバイス固有ID, UNIQUE |
| device_name | text | nullable |
| fcm_token | text | nullable |
| is_notify | integer | 0=通知OFF, 1=通知ON（デフォルト 0） |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | default now() |

- 1ユーザーが複数デバイスを持てる（マルチデバイス対応）
- `is_notify=0` のデバイスには通知しない（ユーザー設定で切り替え可能）

---

## Edge Function: pushNotify

**場所**: `supabase_schema/supabase/functions/pushNotify/index.ts`

**トリガー**: Supabase Database Webhook（orders テーブルの UPDATE）

### 動作条件

```typescript
// 提供ステータスが「未提供(0)」→「提供済(1)」に変わった場合のみ通知
if (payload.old_record.provided_status == '0' && payload.record.provided_status == '1')
```

### 処理フロー

```
1. orders.user_id で user_fcm_tokens を検索
2. レコードなし → 404 を返して終了
3. is_notify=1 かつ fcm_token が存在するデバイスを抽出
4. 対象デバイスが 0 件 → 200 を返して終了（通知OFF）
5. Google サービスアカウントで FCM アクセストークン取得
6. 全対象デバイスに Promise.all で並列送信
```

### 通知内容

| 項目 | 値 |
|---|---|
| title | `【受取番号:XX】` |
| body | `商品のご用意ができました！お待ちしております` |
| data.order_id | 注文ID |

---

## 関連ファイル一覧

| ファイル | 役割 |
|---|---|
| `lib/app/app.dart` | Google OAuth コールバック処理、起動時 FCM 登録 |
| `lib/services/notification_permission_service.dart` | 通知許可リクエストと FCM トークン登録のオーケストレーション |
| `lib/services/auth_service.dart` | `setFcmTokenAndNotifySetting()` の実装 |
| `lib/data/repository/user_fcm_tokens.dart` | Supabase `user_fcm_tokens` テーブルへの CRUD |
| `lib/core/services/device/device_id_service.dart` | デバイスID・デバイス名の取得 |
| `lib/screens/starbucks_user_side/signin/login.dart` | メール/パスワードログイン後の FCM 登録、トークンリフレッシュ監視 |
| `supabase_schema/supabase/functions/pushNotify/index.ts` | Push 通知送信 Edge Function |
| `supabase_schema/supabase/migrations/` | `user_fcm_tokens` テーブル定義（マルチデバイス対応済み） |

---

## トラブルシューティング

### Push 通知が届かない場合のチェックリスト

1. **`user_fcm_tokens` にレコードが存在するか確認**  
   Supabase Dashboard → Table Editor → `user_fcm_tokens` でユーザーの行を確認

2. **`is_notify` が 1 になっているか確認**  
   `is_notify=0` の場合は通知OFF設定になっている

3. **Edge Function のログを確認**  
   Supabase Dashboard → Edge Functions → `pushNotify` → Logs  
   `No records found for user_id` が出ていれば FCM トークン未登録が原因

4. **OS の通知許可を確認**  
   端末の設定 → アプリ → 通知が許可されているか

5. **FCM トークンの再登録**  
   アプリを一度完全終了して再起動すると、`_initializeApp()` の起動時登録処理が走る
