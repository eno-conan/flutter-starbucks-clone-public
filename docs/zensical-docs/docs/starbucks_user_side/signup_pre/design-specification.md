# 仮会員登録機能 設計仕様書

## 1. 概要

このドキュメントは、仮会員登録機能のソフトウェア設計原則、アーキテクチャパターン、コンポーネント設計について記載します。

## 2. アーキテクチャ設計

### 2.1 全体アーキテクチャ

```
┌─────────────────────────────────────────┐
│                UI Layer                  │
│  ┌─────────────┐  ┌─────────────────────┐ │
│  │ PreSignUp   │  │ _ButtonSendEmail    │ │
│  │ (StatefulWidget)│  │ (StatelessWidget)   │ │
│  └─────────────┘  └─────────────────────┘ │
│  ┌─────────────┐  ┌─────────────────────┐ │
│  │ _Header     │  │ _Form               │ │
│  │ (StatelessWidget)│  │ (StatefulWidget)    │ │
│  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────┤
│              Business Logic              │
│  ┌─────────────────────────────────────┐ │
│  │ Email Validation                    │ │
│  │ Form State Management               │ │
│  │ Token Generation                    │ │
│  └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│               Data Layer                 │
│  ┌─────────────┐  ┌─────────────────────┐ │
│  │ Supabase    │  │ PreSignupUsers      │ │
│  │ Client      │  │ Model               │ │
│  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────┘
```

### 2.2 レイヤー分離原則

#### UIレイヤー
- **責任**: ユーザーインターフェースの表示と入力受付
- **特徴**: Stateful/StatelessWidgetの適切な使い分け
- **依存**: Business Logicレイヤーのみに依存

#### Business Logicレイヤー
- **責任**: アプリケーションのビジネスルールと状態管理
- **特徴**: UIに依存しない純粋なロジック
- **依存**: Data Layerのみに依存

#### Data Layerレイヤー
- **責任**: 外部データソースとの連携
- **特徴**: Supabaseクライアントとデータモデル
- **依存**: 外部ライブラリのみに依存

## 3. コンポーネント設計

### 3.1 Widgetアーキテクチャパターン

#### 3.1.1 Composition over Inheritance
```dart
// ✅ 良い例：コンポジションによる設計
class PreSignUp extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: const [
            _Header(),    // 独立したコンポーネント
            _Form(),      // 独立したコンポーネント
          ]
        )
      ),
    );
  }
}
```

#### 3.1.2 Single Responsibility Principle
- **_Header**: ページタイトル表示のみ
- **_Form**: フォーム機能のみ
- **_ButtonSendEmail**: 送信処理のみ

### 3.2 状態管理パターン

#### 3.2.1 Local State Management
```dart
class _FormState extends State<_Form> {
  // 単一責任の状態変数
  final TextEditingController _emailController = TextEditingController();
  bool _isAgreed = false;
  String? _emailError;
  bool _isFormValid = false;
  
  // 状態更新の単一エントリーポイント
  void _updateFormValidity() {
    setState(() {
      _isFormValid = _isEmailValid(_emailController.text) && _isAgreed;
    });
  }
}
```

#### 3.2.2 状態の不変性
- 状態変更は必ず`setState()`内で実行
- 状態変数の直接操作を避ける
- イミュータブルなデータモデルの使用

## 4. 設計パターン

### 4.1 Factory Pattern（Token生成）
```dart
class TokenFactory {
  static String createSecureToken({int length = 32}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }
}
```

### 4.2 Strategy Pattern（バリデーション）
```dart
abstract class ValidationStrategy {
  bool validate(String input);
  String? getErrorMessage();
}

class EmailValidationStrategy implements ValidationStrategy {
  @override
  bool validate(String input) {
    return RegExp(r'^.+@.+\..+$').hasMatch(input);
  }
  
  @override
  String? getErrorMessage() => '不正なメールアドレス';
}
```

### 4.3 Observer Pattern（状態監視）
```dart
@override
void initState() {
  super.initState();
  // TextEditingControllerがObservableの役割
  _emailController.addListener(_updateFormValidity);
}
```

## 5. エラーハンドリング設計

### 5.1 エラー分類

#### 5.1.1 User Input Errors
- **バリデーションエラー**: フォーム入力検証
- **UI表示**: リアルタイムエラーメッセージ
- **回復方法**: ユーザー入力修正

#### 5.1.2 System Errors
- **ネットワークエラー**: API通信失敗
- **UI表示**: ダイアログまたはスナックバー
- **回復方法**: リトライ機能

#### 5.1.3 Business Logic Errors
- **重複データエラー**: メールアドレス重複
- **UI表示**: 専用エラーダイアログ
- **回復方法**: 異なるデータ入力

### 5.2 エラー処理パターン
```dart
// Result型パターン
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.error);
  final String error;
}
```

## 6. セキュリティ設計

### 6.1 クライアントサイドセキュリティ

#### 6.1.1 Input Sanitization
- 入力値の正規化
- XSS攻撃対策
- 不正文字の除去

#### 6.1.2 Token Security
- `Random.secure()`使用による暗号学的安全性
- 十分な長さ（32文字）確保
- 推測困難な文字セット使用

### 6.2 通信セキュリティ
- HTTPS通信の強制
- Supabase Row Level Security（RLS）の活用
- API Key の適切な管理

## 7. パフォーマンス設計

### 7.1 レンダリング最適化

#### 7.1.1 Const Constructor使用
```dart
// ✅ パフォーマンス最適化
const _Header();
const SizedBox(height: 16);
const Text('メールアドレス');
```

#### 7.1.2 不要な再ビルド防止
- Widgetの適切な分割
- `setState()`の最小限使用
- 状態変更の局所化

### 7.2 メモリ管理
```dart
@override
void dispose() {
  _emailController.dispose();  // リソース解放
  super.dispose();
}
```

## 8. テスタビリティ設計

### 8.1 依存性注入
```dart
class EmailService {
  EmailService(this.client);
  final SupabaseClient client;
  
  Future<bool> checkEmailExists(String email) async {
    // テスト時にモッククライアントを注入可能
  }
}
```

### 8.2 Pure Function設計
```dart
// ✅ テストしやすい純粋関数
bool isEmailValid(String email) {
  return RegExp(r'^.+@.+\..+$').hasMatch(email);
}

String createTokenValue() {
  // 副作用なし、テスト可能
}
```

## 9. 拡張性設計

### 9.1 プラグインアーキテクチャ
```dart
abstract class SignupPlugin {
  Future<void> onSignupStart();
  Future<void> onSignupComplete();
  Future<void> onSignupError(Exception error);
}
```

### 9.2 設定駆動設計
```dart
class SignupConfig {
  const SignupConfig({
    this.tokenLength = 32,
    this.emailValidationPattern = r'^.+@.+\..+$',
    this.maxRetryCount = 3,
  });
  
  final int tokenLength;
  final String emailValidationPattern;
  final int maxRetryCount;
}
```

## 10. 国際化・ローカライゼーション設計

### 10.1 文字列リソース管理
```dart
class SignupStrings {
  static const emailLabel = 'メールアドレス';
  static const sendButton = '送信する';
  static const errorInvalidEmail = '不正なメールアドレス';
  static const errorDuplicateEmail = 'ご入力されたメールアドレスは既に登録されています。';
}
```

### 10.2 地域固有設定
- 日本語UI対応
- 日本の入力慣習対応
- 日本のプライバシー法規制対応

## 11. モニタリング・ロギング設計

### 11.1 ログレベル設計
```dart
enum LogLevel { debug, info, warning, error, critical }

class Logger {
  static void log(LogLevel level, String message, [Object? error]) {
    if (kDebugMode) {
      print('${level.name.toUpperCase()}: $message');
      if (error != null) print('Error: $error');
    }
  }
}
```

### 11.2 ユーザー行動追跡
- フォーム入力開始
- バリデーションエラー発生
- 送信成功・失敗
- エラーダイアログ表示

## 12. 設計原則の適用

### 12.1 SOLID原則

#### Single Responsibility Principle
- 各Widgetは単一の責任を持つ
- 各関数は単一の機能を実装

#### Open/Closed Principle
- バリデーション機能の拡張可能性
- 新しいエラーハンドリングの追加容易性

#### Liskov Substitution Principle
- Widget階層での適切な継承
- インターフェースの一貫性

#### Interface Segregation Principle
- 必要な機能のみを公開
- 不要な依存関係の排除

#### Dependency Inversion Principle
- 抽象への依存
- 具象クラスへの直接依存回避

### 12.2 DRY原則
- 共通ロジックの関数化
- 設定値の定数化
- 重複コードの排除

### 12.3 KISS原則
- シンプルな実装
- 過度な抽象化の回避
- 理解しやすい構造

## 13. 変更履歴

| 日付 | 変更内容 | 担当者 |
|------|---------|--------|
| 2025-09-23 | 初版作成 | PR #268対応 |
| 2025-09-23 | アーキテクチャ設計とコンポーネント設計を追加 | 設計書作成 |

## 14. 関連ドキュメント

- [概要仕様書](./overview.md)
- [UI仕様書](./ui-specification.md)
- [コード品質・ドキュメント仕様書](./code-quality-specification.md)
- [変更履歴](./changelog.md)