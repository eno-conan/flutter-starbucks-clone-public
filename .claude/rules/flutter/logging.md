---
description: LoggerServiceを使用したログ出力ガイドライン
---

# ログ出力ガイドライン

## 概要

このドキュメントは、プロジェクトにおけるログ出力の標準的な使用方法とベストプラクティスを定義します。
`LoggerService`クラスを使用した適切なログ出力により、開発・デバッグ・運用における問題の迅速な特定と解決を支援します。

## LoggerServiceの基本構成

### 使用可能なログレベル

LoggerServiceは6つのログレベルを提供していますが、基本的には**info**と**warn**の2レベルを使用します。

```dart
import 'package:app/core/services/logger_service.dart';

// 基本の2レベル（推奨）
LoggerService.info('ユーザー認証が完了しました');
LoggerService.warn('認証に失敗しました', error);

// 追加レベル（必要に応じて使用）
LoggerService.debug('デバッグ情報: ${debugData}');
LoggerService.error('予期しないエラーが発生しました', error, stackTrace);
LoggerService.trace('メソッド開始: methodName()');
LoggerService.fatal('アプリケーション終了レベルのエラー', error, stackTrace);
```

## ログレベル別使用指針

### 1. info（情報ログ）- 主要使用レベル

正常な処理フローの重要なポイントで使用します。

#### 使用ケース
- ユーザーアクションの開始・完了
- API呼び出しの成功
- 重要な状態変更
- データ処理の進捗

#### 実装例
```dart
// ユーザー認証
LoggerService.info('ユーザーログイン開始: ${user.email}');
LoggerService.info('認証処理完了: ユーザーID=${user.id}');

// API通信
LoggerService.info('商品データ取得開始');
LoggerService.info('商品データ取得完了: ${products.length}件');

// 画面遷移
LoggerService.info('画面遷移: ${fromScreen} → ${toScreen}');

// データ保存
LoggerService.info('ユーザー設定保存完了');
```

### 2. warn（警告ログ）- 主要使用レベル

例外やエラーが発生した箇所、特にthrowするケースで使用します。

#### 使用ケース
- 例外をthrowする直前
- try-catchのcatch節
- 予期しない状態や値
- リトライ可能なエラー

#### 実装例
```dart
// throwする例（issue記載のgetUserIdパターン）
String getUserId() {
  final SupabaseClient supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) {
    LoggerService.warn('ユーザーが認証されていません');
    throw Exception('ユーザーが認証されていません');
  }
  return userId;
}

// try-catchでのエラーハンドリング
try {
  await apiService.updateUserProfile(profile);
  LoggerService.info('プロフィール更新完了');
} catch (error) {
  LoggerService.warn('プロフィール更新に失敗しました', error);
  // UIにエラー表示やリトライ処理
}

// 予期しない値の検出
if (response.statusCode != 200) {
  LoggerService.warn('APIから予期しないステータスコードを受信: ${response.statusCode}');
}
```

### 3. その他のログレベル（補助的使用）

#### debug（デバッグログ）
開発時の詳細な変数の状態確認に使用
```dart
LoggerService.debug('リクエストパラメータ: ${requestParams.toString()}');
LoggerService.debug('処理時間: ${stopwatch.elapsedMilliseconds}ms');
```

#### error（エラーログ）
回復困難なシステムエラーに使用
```dart
LoggerService.error('データベース接続エラー', error, stackTrace);
```

#### trace（トレースログ）
メソッドの開始・終了など、実行フローの詳細追跡に使用
```dart
LoggerService.trace('_validateUserInput() 開始');
```

#### fatal（致命的エラーログ）
アプリケーション終了レベルの重大なエラーに使用
```dart
LoggerService.fatal('初期化に失敗し、アプリケーションを継続できません', error, stackTrace);
```

## 実装パターンとベストプラクティス

### 1. 基本的な実装パターン

#### サービス層でのログ出力
```dart
class UserService {
  Future<User> fetchUser(String userId) async {
    LoggerService.info('ユーザー情報取得開始: userID=$userId');

    try {
      final response = await _httpClient.get('/users/$userId');
      final user = User.fromJson(response.data);

      LoggerService.info('ユーザー情報取得完了: ${user.name}');
      return user;
    } catch (error) {
      LoggerService.warn('ユーザー情報取得に失敗しました: userID=$userId', error);
      rethrow;
    }
  }
}
```

#### Riverpod Provider でのログ出力
```dart
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  LoggerService.info('UserProvider実行開始: userID=$userId');

  try {
    final userService = ref.read(userServiceProvider);
    final user = await userService.fetchUser(userId);
    return user;
  } catch (error) {
    LoggerService.warn('UserProvider実行エラー: userID=$userId', error);
    rethrow;
  }
});
```

#### Widget内でのログ出力
```dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        LoggerService.info('ログインボタン押下');

        try {
          await ref.read(authProvider.notifier).signIn(email, password);
          LoggerService.info('ログイン成功');

          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } catch (error) {
          LoggerService.warn('ログインに失敗しました', error);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ログインに失敗しました')),
            );
          }
        }
      },
      child: const Text('ログイン'),
    );
  }
}
```

### 2. コメントアウトされたdebugPrintの置き換え

#### 置き換え前（削除対象）
```dart
try {
  await processPayment();
} catch (e) {
  // debugPrint('Payment failed: $e');  ← このような行を削除
}
```

#### 置き換え後
```dart
try {
  await processPayment();
  LoggerService.info('決済処理完了');
} catch (error) {
  LoggerService.warn('決済処理に失敗しました', error);
  // エラー処理の実装
}
```

### 3. 適切な文脈情報の含め方

#### 推奨: 関連する識別情報を含める
```dart
LoggerService.info('注文作成開始: userID=$userId, items=${items.length}個');
LoggerService.warn('在庫不足: productID=$productId, requested=$quantity, available=$stock');
```

#### 推奨: 処理の前後関係を明確にする
```dart
LoggerService.info('プロフィール画像アップロード開始');
// アップロード処理
LoggerService.info('プロフィール画像アップロード完了: fileSize=${file.length}bytes');
```

## ログ出力時の注意事項

### 1. パフォーマンスへの配慮

- ログ出力は処理を停止させない非同期処理として実装されています
- 大量のデータや複雑なオブジェクトをログ出力する際は適度に省略する

```dart
// ❌ 避ける: 大量データの全出力
LoggerService.info('全商品データ: ${allProducts.toString()}');

// ✅ 推奨: 要約情報の出力
LoggerService.info('商品データ読み込み完了: ${allProducts.length}件');
```

### 2. 機密情報の保護

パスワード、APIキー、個人情報などの機密データをログに含めないよう注意する

```dart
// ❌ 危険: パスワードを出力
LoggerService.info('ログイン試行: email=$email, password=$password');

// ✅ 安全: 機密情報を除外
LoggerService.info('ログイン試行: email=$email');
```

### 3. 適切な日本語メッセージ

ユーザーに表示される可能性があるエラーメッセージと一貫性を保つ

```dart
// 推奨: 分かりやすい日本語メッセージ
LoggerService.warn('ネットワーク接続エラーが発生しました', error);
LoggerService.info('商品をカートに追加しました: ${product.name}');
```

## デバッグとトラブルシューティング

### 1. ログレベルの調整

開発環境では詳細ログ、本番環境では重要ログのみを出力するよう設定可能

### 2. ログの可視性

PrettyPrinterにより以下の特徴でログが出力されます：
- 色付きログで可読性向上
- タイムスタンプ付きで時系列追跡可能
- 絵文字でレベル識別が容易
- スタックトレース情報（error/fatal/warn）

### 3. ログ出力例

```
💡 2024-10-30 15:00:01.234 [INFO] ユーザーログイン開始: user@example.com
⚠️  2024-10-30 15:00:02.567 [WARN] 認証に失敗しました
   ┌─────────────────────────────────────
   │ Exception: Invalid credentials
   └─────────────────────────────────────
```

## まとめ

- **基本運用**: `info`と`warn`の2レベルを中心に使用
- **info**: 正常フローの重要ポイント
- **warn**: 例外・エラー発生箇所（特にthrowケース）
- **処理継続**: ログ出力で処理を停止しない
- **機密保護**: パスワードなどの機密情報は出力しない
- **文脈情報**: 識別情報や関連データを適度に含める

このガイドラインに従うことで、効果的なログ出力による開発効率向上とトラブルシューティングの迅速化を実現できます。
