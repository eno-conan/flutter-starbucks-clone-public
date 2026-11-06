# ログイン機能 概要仕様書

## 1. 概要

- Starbucks クローンアプリの、ログイン機能の仕様書。
- ユーザーは、パスキー、Google アカウント、メールアドレス・パスワードのいずれかで、アプリにログインできる。
- 画面での並び順は、パスキー（使える端末のみ）→ Google → メール・パスワード（[設計書 0002](../../design/0002-login-methods-organization.md)）。

## 2. 主要コンポーネント

### 2.1 ファイル構成

```
lib/screens/starbucks_user_side/signin/
├── login.dart                          // LoginPage（状態・遷移・ローディング）と _Header
└── widgets/
    ├── passkey_login_button.dart       // パスキーでログイン
    ├── google_login_button.dart        // Google ログイン
    ├── email_password_login_form.dart  // メール・パスワードのフォーム
    └── reset_password_link.dart        // パスワードリセットのリンク
```

### 2.2 関連ファイル

```
lib/services/
├── auth_service.dart             // 認証サービス（メール・パスワード / Google / サインアウト）
├── passkey_auth_service.dart     // パスキーの認証サービス
└── fcm_token_sync_service.dart   // ログイン後の FCM トークン登録

lib/provider/
└── passkey_state_provider.dart   // この端末でパスキーが使えるか

lib/app/app.dart                  // OAuth コールバック（ディープリンク）の処理
lib/screens/starbucks_user_side/home/main.dart  // ログイン成功時の遷移先
lib/constants/id_keys.dart        // 定数定義（API キーなど）
```

### 2.3 メインクラス

| クラス名 | 役割 | ファイル |
|---------|------|---------|
| `LoginPage` | メインログイン画面 | `login.dart` |
| `PasskeyLoginButton` | パスキーでログインするボタン | `widgets/passkey_login_button.dart` |
| `GoogleLoginButton` | Googleログインボタン | `widgets/google_login_button.dart` |
| `EmailPasswordLoginForm` | メール・パスワードログインフォーム | `widgets/email_password_login_form.dart` |
| `ResetPasswordLink` | パスワードリセットリンク | `widgets/reset_password_link.dart` |
| `AuthService` | 認証処理サービス | `lib/services/auth_service.dart` |
| `PasskeyAuthService` | パスキーの認証サービス | `lib/services/passkey_auth_service.dart` |
| `FcmTokenSyncService` | 認証状態に連動した FCM トークン登録 | `lib/services/fcm_token_sync_service.dart` |

## 3. 機能概要

### 3.1 認証方式

1. **パスキー認証**
    - この端末でパスキーが使える場合だけ、ボタンを表示する。
    - 画面表示時の自動起動はしない。必ずボタンのタップを起点にする。
    - 指紋・顔認証は独立した手段ではない。パスキーを使うときに OS が出す解錠の画面。

2. **Googleアカウント認証**
    - Supabase OAuth経由でブラウザを起動して認証
    - カスタムスキーム（`testingapp://callback`）のディープリンクでアプリに戻り、セッションを確立

3. **メールアドレス・パスワード認証**
    - Supabaseを使用したメール・パスワード認証
    - リアルタイムバリデーション機能

!!! note "端末にパスワードは保存しない"
    - 旧方式（`local_auth` による指紋認証）は廃止した。
    - 旧方式で保存したログイン情報は、アプリ起動のたびに削除する（`AuthService.purgeLegacyCredentials`）。
    - セッションの扱いは [設計書 0005](../../design/0005-login-and-session.md)、パスキーは [設計書 0001](../../design/0001-passkey-introduction.md) を参照。

### 3.2 状態管理

- `AuthState`によるリアルタイム認証状態監視
- FCMトークンの登録は、ログイン手段によらず `FcmTokenSyncService` が `onAuthStateChange` を起点に行う（[設計書 0003](../../design/0003-push-notification.md)）
- ローディング状態の管理

## 4. 技術スタック

| 技術 | 用途 |
|------|------|
| Supabase | バックエンド認証サービス・Google OAuth |
| passkeys | パスキー（WebAuthn）の端末側の処理 |
| app_links | OAuthコールバックのディープリンク処理 |
| Firebase Messaging | プッシュ通知用トークン管理 |
| Riverpod | 状態管理・依存性注入（`authServiceProvider` など） |
| Go Router | ナビゲーション |

## 5. セキュリティ

- OAuth 2.0準拠のGoogle認証（Supabase OAuth経由）
- Supabaseによるセキュアな認証管理
- トークンの適切なライフサイクル管理
- OAuthコールバックのホスト・スキーム検証

## 6. ユーザビリティ

- リアルタイムフォームバリデーション
- 視覚的フィードバック（ローディングインジケータ）
- エラーメッセージのスナックバー表示
- パスワード表示/非表示切り替え機能

## 7. 関連ドキュメント

- [UI仕様書](./ui-specification.md)
- [設計書 0001: パスキー導入](../../design/0001-passkey-introduction.md)
- [設計書 0002: ログイン手段の整理](../../design/0002-login-methods-organization.md)
- [設計書 0005: ログインとセッション管理](../../design/0005-login-and-session.md)
- [エラーハンドリング仕様書](./error-handling.md)
- [テスト仕様書](./testing-specification.md)