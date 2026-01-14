# ログイン機能 概要仕様書

## 1. 概要

このドキュメントは、Starbucksクローンアプリケーションのログイン機能に関する仕様書です。
ユーザーはメールアドレス・パスワードまたはGoogleアカウントを使用してアプリにログインできます。

## 2. 主要コンポーネント

### 2.1 ファイル構成

```
lib/screens/starbucks_user_side/signin/
└── login.dart                    // メインのログインページ
```

### 2.2 関連ファイル

```
lib/screens/starbucks_user_side/
├── auth_service.dart             // 認証サービス
└── home/main.dart               // ログイン成功時の遷移先

lib/constants/
└── id_keys.dart                 // 定数定義（API キーなど）
```

### 2.3 メインクラス

| クラス名 | 役割 | ファイル |
|---------|------|---------|
| `LoginPage` | メインログイン画面 | login.dart |
| `EmailPasswordLoginForm` | メール・パスワードログインフォーム | login.dart |
| `GoogleLoginButton` | Googleログインボタン | login.dart |
| `ResetPasswordLink` | パスワードリセットリンク | login.dart |
| `AuthService` | 認証処理サービス | auth_service.dart |

## 3. 機能概要

### 3.1 認証方式

1. **メールアドレス・パスワード認証**
   - Supabaseを使用したメール・パスワード認証
   - リアルタイムバリデーション機能

2. **Googleアカウント認証**
   - Google Sign-InとSupabaseの連携
   - OAuthトークンを使用した認証

3. **生体認証（実装済み）**
   - 指紋認証機能（local_auth使用）
   - 認証情報のセキュアストレージ保存
   - 自動ログイン機能

### 3.2 状態管理

- `AuthState`によるリアルタイム認証状態監視
- FCMトークンの自動更新・登録
- ローディング状態の管理

## 4. 技術スタック

| 技術 | 用途 |
|------|------|
| Supabase | バックエンド認証サービス |
| Google Sign-In | Google OAuth認証 |
| Firebase Messaging | プッシュ通知用トークン管理 |
| GetIt | 依存性注入 |
| Go Router | ナビゲーション |

## 5. セキュリティ

- OAuth 2.0準拠のGoogle認証
- Supabaseによるセキュアな認証管理
- トークンの適切なライフサイクル管理
- プラットフォーム固有の例外処理

## 6. ユーザビリティ

- リアルタイムフォームバリデーション
- 視覚的フィードバック（ローディングインジケータ）
- エラーメッセージのスナックバー表示
- パスワード表示/非表示切り替え機能

## 7. 関連ドキュメント

- [UI仕様書](./ui-specification.md)
- [認証フロー仕様書](./authentication-flow.md)
- [エラーハンドリング仕様書](./error-handling.md)
- [テスト仕様書](./testing-specification.md)