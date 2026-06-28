# 仮会員登録機能 概要仕様書

## 1. 概要

このドキュメントは、Starbucksクローンアプリケーションの仮会員登録（Pre Sign Up）機能に関する仕様書です。
ユーザーはメールアドレスを入力し、利用規約に同意することで仮会員登録メールを受信できます。

## 2. 主要コンポーネント

### 2.1 ファイル構成

```
lib/screens/starbucks_user_side/signup_pre/
├── pre_signup.dart              // メインの仮会員登録画面
└── pre_signup_completion.dart   // 登録完了画面
```

### 2.2 関連ファイル

```
lib/core/models/
└── pre_signup_users.dart        // 仮会員データモデル

lib/constants/
├── supabase_tables.dart        // テーブル名定数
└── supabase_rpcs.dart          // RPC関数名定数
```

### 2.3 メインクラス

| クラス名 | 役割 | ファイル |
|---------|------|---------|
| `PreSignUp` | 新規会員登録の仮登録メール送信フォーム | pre_signup.dart |
| `_Header` | ページヘッダー表示 | pre_signup.dart |
| `_Form` | メール入力フォーム | pre_signup.dart |
| `_FormState` | フォーム状態管理 | pre_signup.dart |
| `_ButtonSendEmail` | メール送信ボタン | pre_signup.dart |

## 3. 機能概要

### 3.1 画面フロー

1. **メールアドレス入力**
   - リアルタイムバリデーション機能
   - 正規表現による形式チェック

2. **利用規約同意**
   - チェックボックスによる同意確認
   - フォーム有効化条件

3. **重複チェック**
   - データベースでの既存メール確認
   - 重複時はエラーダイアログ表示

4. **仮登録処理**
   - 32桁セキュアトークン生成
   - Supabaseテーブルへのデータ挿入

### 3.2 バリデーション機能

#### メールアドレス検証
```dart
bool _isEmailValid(String email) {
  return RegExp(r'^.+@.+\..+$').hasMatch(email);
}
```

#### フォーム有効性判定
- メールアドレス形式が正しい
- 利用規約に同意している
- 上記両方を満たす場合にボタンが有効化

### 3.3 トークン生成機能

#### セキュリティ仕様
```dart
String createTokenValue() {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rand = Random.secure();
  return List.generate(32, (index) => chars[rand.nextInt(chars.length)]).join();
}
```

- **文字種**: 英数字（大文字・小文字・数字）
- **長さ**: 32文字
- **生成方式**: Random.secure()使用

## 4. データベース連携

### 4.1 使用テーブル
- `pre_signup_users`: 仮会員情報格納テーブル

### 4.2 使用RPC関数
- `checkSignupEmailExists`: メールアドレス重複チェック

### 4.3 データフロー

1. **重複チェック**
   ```dart
   final response = await supabase.rpc(
     Rpcs.checkSignupEmailExists,
     params: {'input_email': email},
   );
   ```

2. **仮会員データ挿入**
   ```dart
   final response = await supabase
     .from(Tables.preSignupUsers)
     .insert(preSignupUsers.toJson())
     .select()
     .single();
   ```

## 5. UI/UX設計

### 5.1 レスポンシブ対応
- `resizeToAvoidBottomInset: false`: キーボード表示時の画面調整
- SafeArea対応によるノッチ・ホームバー対応

### 5.2 視覚的フィードバック
- リアルタイムフォーム更新
- ローディングインジケータ表示
- エラーダイアログ表示

### 5.3 アクセシビリティ
- フォーム要素への適切なラベル設定
- エラーメッセージの明確な表示

## 6. エラーハンドリング

### 6.1 入力検証エラー
- 不正なメールアドレス形式
- 利用規約未同意

### 6.2 データベースエラー
- 既存メールアドレス重複
- ネットワーク接続エラー
- サーバーエラー

### 6.3 エラー表示方式
```dart
void _showAlreadyInputRegisteredEmailAddressDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (BuildContext context) => Dialog(/* ... */),
  );
}
```

## 7. セキュリティ考慮事項

### 7.1 データ保護
- セキュアトークン生成による認証強化
- メールアドレスの適切な検証

### 7.2 入力値検証
- フロントエンド・バックエンド双方での検証
- SQLインジェクション対策（ParameterizedQuery使用）

## 8. パフォーマンス

### 8.1 最適化項目
- リアルタイムバリデーションの適切な間隔
- 不要な再描画の抑制（`setState`の最適化）

### 8.2 レスポンス性能
- データベースクエリの最適化
- 非同期処理による UI の応答性維持

## 9. 技術スタック

| 技術 | 用途 |
|------|------|
| Flutter | UIフレームワーク |
| Supabase | バックエンドサービス |
| Go Router | ナビゲーション管理 |
| Dart Random.secure | セキュアトークン生成 |

## 10. 関連ドキュメント

- [設計仕様書](./design-specification.md)
- [UI仕様書](./ui-specification.md)
- [コード品質・ドキュメント仕様書](./code-quality-specification.md)
- [変更履歴](./changelog.md)
- [データベース設計書](./database-specification.md)
- [テスト仕様書](./testing-specification.md)
- [エラーハンドリング仕様書](./error-handling.md)

## 11. 変更履歴

| 日付 | 変更内容 | 担当者 |
|------|---------|--------|
| 2025-09-23 | 初版作成 | システム自動生成 |
| 2025-09-23 | トークン生成関数名修正対応 | PR #258 |
| 2025-09-23 | ドキュメンテーションコメント簡素化対応 | PR #266 |