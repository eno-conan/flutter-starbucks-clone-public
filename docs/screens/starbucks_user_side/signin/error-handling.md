# ログイン機能 エラーハンドリング仕様書

## 1. エラーハンドリング概要

ログイン機能では、認証プロセス、ネットワーク通信、ユーザー入力バリデーション等で発生する可能性のあるエラーを適切に処理し、ユーザーにわかりやすいフィードバックを提供します。

## 2. エラー分類

### 2.1 バリデーションエラー（クライアントサイド）

| エラータイプ | 発生条件 | エラーメッセージ | 対処方法 |
|-------------|---------|-----------------|---------|
| 必須入力エラー（メール） | メールアドレス未入力 | "メールアドレスを入力してください" | フォームバリデーション |
| 必須入力エラー（パスワード） | パスワード未入力 | "パスワードを入力してください" | フォームバリデーション |

#### 実装詳細

```dart
// メールアドレスバリデーター
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'メールアドレスを入力してください';
  }
  return null;
}

// パスワードバリデーター  
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'パスワードを入力してください';
  }
  return null;
}
```

### 2.2 認証エラー（サーバーサイド）

#### 2.2.1 メール・パスワード認証エラー

```dart
Future<void> _handleAuthenticationByEmailAndPassword() async {
  try {
    await widget.authService.signInWithEmailAndPassword(
      _emailController.text,
      _passwordController.text,
    );
  } on PlatformException catch (e) {
    widget.onLoadingStateChanged(false);
    if (kDebugMode) {
      print('ログイン処理でエラー発生: $e');
    }
    widget.showSnackBar('認証処理に失敗しました(メールアドレス)');
  } catch (err) {
    widget.onLoadingStateChanged(false);
    widget.showSnackBar('$err:認証処理に失敗(メールアドレス)');
  }
}
```

#### 2.2.2 Google認証エラー

```dart
Future<void> _handleAuthenticationByGoogle() async {
  try {
    if (email != null) {
      await authService.signOutWithGoogle();
      showSnackBar('サインアウトしました。');
    } else {
      await authService.signInWithGoogle();
      onLoginSuccess();
    }
  } on PlatformException catch (e) {
    onLoadingStateChanged(false);
    if (kDebugMode) {
      print(email != null ? 'ログアウト処理でエラー発生: $e' : 'ログイン処理でエラー発生: $e');
    }
    showSnackBar('認証処理に失敗しました(PlatformException)');
  } catch (err) {
    onLoadingStateChanged(false);
    showSnackBar('$err:認証処理に失敗しました(OtherException)');
  }
}
```

## 3. Google Sign-In 固有エラー

### 3.1 プラットフォームサポートエラー

```dart
Future<void> signInWithGoogle() async {
  try {
    if (!_googleSignIn.supportsAuthenticate()) {
      throw Exception('Authenticate not supported on this platform');
    }
    // 認証処理続行
  } catch (error) {
    rethrow;
  }
}
```

### 3.2 認証失敗エラー

```dart
Future<void> _performAuthentication() async {
  final googleUser = await _googleSignIn.attemptLightweightAuthentication();
  
  if (googleUser == null) {
    throw Exception('attemptLightweightAuthentication failed');
  }
  // 処理続行
}
```

### 3.3 スコープ認可エラー

```dart
if (authorization == null) {
  final authorizeResult = await googleUser.authorizationClient.authorizeScopes(scopes);
  
  if (authorizeResult.accessToken.isEmpty) {
    throw Exception('Failed to get authorization after user granted it');
  }
  authorization = authorizeResult;
}
```

### 3.4 IDトークンエラー

```dart
final idToken = googleAuth.idToken;
if (idToken == null) {
  throw Exception('No ID Token found.');
}
```

## 4. 生体認証エラー（準備済み）

### 4.1 プラットフォーム例外処理

```dart
Future<void> _getAvailableBiometrics() async {
  try {
    // availableBiometrics = await auth.getAvailableBiometrics();
  } on PlatformException catch (e) {
    // availableBiometrics = <BiometricType>[];
    print(e);
  }
  
  if (!mounted) return;
  
  setState(() {
    // _availableBiometrics = availableBiometrics;
  });
}
```

### 4.2 認証処理エラー

```dart
Future<void> _authenticateWithBiometrics() async {
  try {
    setState(() {
      _isAuthenticating = true;
      _authorized = 'Authenticating';
    });
    
    // 生体認証処理
    
  } on PlatformException catch (e) {
    print(e);
    setState(() {
      _isAuthenticating = false;
      _authorized = 'Error - ${e.message}';
    });
    return;
  }
  
  if (!mounted) return;
}
```

## 5. FCMトークン関連エラー

### 5.1 トークンリフレッシュエラー

```dart
try {
  FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
    await _authService.setFcmTokenAndNotifySetting(fcmToken, true);
  });
} catch (e) {
  if (kDebugMode) {
    print('FCMトークンリフレッシュエラー: $e');
  }
}
```

### 5.2 トークン設定エラー

```dart
Future<void> setFcmTokenAndNotifySetting(String fcmToken, bool isNotify) async {
  final userId = supabase.auth.currentUser!.id;
  
  try {
    await supabase.from(Tables.userFcmTokens).upsert({
      'user_id': userId,
      'fcm_token': fcmToken,
      'is_notify': isNotify ? 1 : 0,
    });
  } catch (error) {
    if (kDebugMode) {
      print('FCMトークン設定エラー: $error');
    }
    rethrow;
  }
}
```

## 6. 初期化エラー

### 6.1 Google Sign-In初期化エラー

```dart
Future<void> _initializeAndNavigate() async {
  try {
    await _authService.initializeGoogleSignIn();
    if (_authService.isAuthenticated()) {
      _navigateToHome();
    }
  } catch (e) {
    if (kDebugMode) {
      print('Google Sign-In initialization/authentication error: $e');
    }
    // エラー処理（ログイン画面への遷移など）
  }
}
```

## 7. ユーザー状態関連エラー

### 7.1 未認証ユーザーエラー

```dart
String getUserId() {
  final SupabaseClient supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) {
    throw Exception('ユーザーが認証されていません');
  }
  return userId;
}
```

### 7.2 セッション取得エラー

```dart
Future<String?> retrieveLoginUser() async {
  try {
    final User? user = supabase.auth.currentUser;
    return user?.email;
  } catch (error) {
    rethrow;
  }
}
```

## 8. Widget状態関連エラー

### 8.1 マウント状態チェック

```dart
if (!mounted) {
  return; // Widgetが既に破棄されている場合は処理を中断
}

void _navigateToHome() {
  if (mounted) {
    context.go(Home.routeName);
  }
}
```

### 8.2 フォーム状態エラー

```dart
void _validateForm() {
  setState(() {
    _isFormValid =
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        // ignore: use_if_null_to_convert_nulls_to_bools
        _formKey.currentState?.validate() == true;
  });
}
```

## 9. エラーメッセージ表示

### 9.1 SnackBar実装

```dart
void _showSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3)
    )
  );
}
```

### 9.2 エラーメッセージ一覧

| カテゴリ | メッセージ | 表示タイミング |
|---------|-----------|---------------|
| バリデーション | "メールアドレスを入力してください" | メールフィールド未入力時 |
| バリデーション | "パスワードを入力してください" | パスワードフィールド未入力時 |
| メール認証 | "認証処理に失敗しました(メールアドレス)" | メール認証失敗時 |
| Google認証 | "認証処理に失敗しました(PlatformException)" | Google認証PlatformException |
| Google認証 | "認証処理に失敗しました(OtherException)" | Google認証その他例外 |
| ログアウト | "サインアウトしました。" | ログアウト成功時 |

## 10. デバッグモード対応

### 10.1 デバッグ専用ログ出力

```dart
if (kDebugMode) {
  print('Google Sign-In initialization/authentication error: $e');
  print('ログイン処理でエラー発生: $e');
  print('FCMトークンリフレッシュエラー: $e');
  print('デバイストークン登録');
}
```

### 10.2 本番環境でのエラー情報制限

- デバッグ詳細情報は`kDebugMode`でラップ
- ユーザーには技術的詳細を含まない簡潔なメッセージを表示
- スタックトレース等の機密情報は本番では出力しない

## 11. ローディング状態管理

### 11.1 エラー時のローディング解除

```dart
try {
  // 認証処理
} catch (error) {
  widget.onLoadingStateChanged(false); // 必ずローディングを解除
  widget.showSnackBar('エラーメッセージ');
}
```

### 11.2 ローディング状態の初期化

```dart
@override
void initState() {
  super.initState();
  // 初期状態でローディングは無効
  // _isLoading = false (デフォルト)
}
```

## 12. エラー復旧戦略

### 12.1 自動リトライ機能

現在の実装では自動リトライ機能はありませんが、将来的な実装に向けた考慮事項：

- ネットワーク一時的なエラー時のリトライ
- トークンリフレッシュ失敗時の再試行
- 認証タイムアウト時の再認証

### 12.2 ユーザーアクション推奨

- 認証失敗時：入力内容の確認を促すメッセージ
- ネットワークエラー時：接続状況の確認を促すメッセージ
- プラットフォームエラー時：アプリ再起動を促すメッセージ

## 13. ログ収集とモニタリング

### 13.1 エラー情報の収集

現在は`print`文による基本的なログ出力のみ実装されています。本番環境では以下の検討が推奨されます：

- Firebase Crashlyticsとの連携
- カスタムログ収集システムの実装
- パフォーマンスメトリクスの追跡

### 13.2 監視指標

- 認証成功/失敗率
- 各認証方式の利用率
- エラーレスポンス時間
- ユーザー離脱率（認証失敗後）