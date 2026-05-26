# ログイン機能 テスト仕様書

## 1. テスト概要

ログイン機能の品質保証のため、単体テスト、ウィジェットテスト、統合テストを実装し、各認証フローの正常動作とエラーハンドリングを検証します。

## 2. テスト分類

### 2.1 単体テスト（Unit Tests）
- AuthServiceクラスのメソッド
- バリデーション関数
- ユーティリティ関数

### 2.2 ウィジェットテスト（Widget Tests）
- UI コンポーネントの表示
- ユーザーインタラクション
- フォームバリデーション

### 2.3 統合テスト（Integration Tests）
- 認証フロー全体
- ナビゲーション
- 外部サービス連携

## 3. 単体テスト仕様

### 3.1 AuthService テスト

#### 3.1.1 認証状態チェック

```dart
group('AuthService Authentication State Tests', () {
  late AuthService authService;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    authService = AuthService();
  });

  test('isAuthenticated returns true when user is logged in', () {
    // Arrange
    when(mockSupabase.auth.currentUser).thenReturn(MockUser());
    
    // Act
    final result = authService.isAuthenticated();
    
    // Assert
    expect(result, true);
  });

  test('isAuthenticated returns false when user is not logged in', () {
    // Arrange
    when(mockSupabase.auth.currentUser).thenReturn(null);
    
    // Act
    final result = authService.isAuthenticated();
    
    // Assert
    expect(result, false);
  });
});
```

#### 3.1.2 ユーザー情報取得テスト

```dart
group('AuthService User Retrieval Tests', () {
  test('retrieveLoginUser returns email when user exists', () async {
    // Arrange
    final mockUser = MockUser();
    when(mockUser.email).thenReturn('test@example.com');
    when(mockSupabase.auth.currentUser).thenReturn(mockUser);
    
    // Act
    final result = await authService.retrieveLoginUser();
    
    // Assert
    expect(result, 'test@example.com');
  });

  test('retrieveLoginUser returns null when user does not exist', () async {
    // Arrange
    when(mockSupabase.auth.currentUser).thenReturn(null);
    
    // Act
    final result = await authService.retrieveLoginUser();
    
    // Assert
    expect(result, null);
  });
});
```

#### 3.1.3 ユーザーID取得テスト

```dart
group('AuthService User ID Tests', () {
  test('getUserId returns user ID when authenticated', () {
    // Arrange
    final mockUser = MockUser();
    when(mockUser.id).thenReturn('user123');
    when(mockSupabase.auth.currentUser).thenReturn(mockUser);
    
    // Act
    final result = authService.getUserId();
    
    // Assert
    expect(result, 'user123');
  });

  test('getUserId throws exception when not authenticated', () {
    // Arrange
    when(mockSupabase.auth.currentUser).thenReturn(null);
    
    // Act & Assert
    expect(() => authService.getUserId(), 
           throwsA(isA<Exception>()));
  });
});
```

### 3.2 認証処理テスト

#### 3.2.1 メール・パスワード認証

```dart
group('Email Password Authentication Tests', () {
  test('signInWithEmailAndPassword calls supabase auth', () async {
    // Arrange
    const email = 'test@example.com';
    const password = 'password123';
    
    // Act
    await authService.signInWithEmailAndPassword(email, password);
    
    // Assert
    verify(mockSupabase.auth.signInWithPassword(
      email: email, 
      password: password
    )).called(1);
  });

  test('signInWithEmailAndPassword rethrows exception on failure', () async {
    // Arrange
    when(mockSupabase.auth.signInWithPassword(
      email: anyNamed('email'),
      password: anyNamed('password')
    )).thenThrow(Exception('Auth failed'));
    
    // Act & Assert
    expect(() => authService.signInWithEmailAndPassword('test@example.com', 'password'),
           throwsA(isA<Exception>()));
  });
});
```

#### 3.2.2 Google認証テスト

`signInWithGoogleOAuth()` はブラウザを起動する外部呼び出しであるため、
ユニットテストでは `supabase.auth.signInWithOAuth()` の呼び出しを検証します。

```dart
group('Google OAuth Authentication Tests', () {
  test('signInWithGoogleOAuth calls supabase signInWithOAuth', () async {
    // Arrange
    when(mockSupabaseClient.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: anyNamed('redirectTo'),
    )).thenAnswer((_) async => true);

    // Act
    await authService.signInWithGoogleOAuth();

    // Assert
    verify(mockSupabaseClient.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: anyNamed('redirectTo'),
    )).called(1);
  });

  test('signInWithGoogleOAuth uses testingapp scheme in debug mode', () async {
    // DebugModeでは 'testingapp://callback' が redirectTo に使われることを確認
    // (kDebugMode が true の場合の動作確認はモックで検証)
    // Note: 実際のブラウザ起動はE2Eテストで検証する
  });
});
```

**方針**: ブラウザ起動後の実際のOAuth認証フローは外部ブラウザを伴うため、
ウィジェットテストでの自動検証が困難です。
OAuth認証後のコールバック処理（`_handleOAuthCallback`）はE2Eテストで検証してください。

### 3.3 FCMトークン管理テスト

```dart
group('FCM Token Management Tests', () {
  test('setFcmTokenAndNotifySetting inserts token with deviceId correctly', () async {
    // Arrange
    const fcmToken = 'mock_fcm_token';
    const isNotify = true;
    const userId = 'user123';
    const deviceId = 'device-uuid-123';
    const deviceName = 'iPhone 15';

    when(mockSupabase.auth.currentUser?.id).thenReturn(userId);

    // Act
    await authService.setFcmTokenAndNotifySetting(
      fcmToken,
      isNotify,
      deviceId: deviceId,
      deviceName: deviceName,
    );

    // Assert
    verify(mockSupabase.from(Tables.userFcmTokens).upsert({
      'user_id': userId,
      'device_id': deviceId,
      'device_name': deviceName,
      'fcm_token': fcmToken,
      'is_notify': 1,
    }, onConflict: 'user_id,device_id')).called(1);
  });

  test('setFcmTokenAndNotifySetting skips when user not logged in', () async {
    // Arrange
    when(mockSupabase.auth.currentUser).thenReturn(null);

    // Act
    await authService.setFcmTokenAndNotifySetting(
      'token',
      true,
      deviceId: 'device-id',
    );

    // Assert
    verifyNever(mockSupabase.from(Tables.userFcmTokens).upsert(any));
  });
});
```

## 4. ウィジェットテスト仕様

### 4.1 LoginPage テスト

#### 4.1.1 基本表示テスト

```dart
group('LoginPage Widget Tests', () {
  testWidgets('displays all required elements', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(MaterialApp(home: LoginPage()));
    
    // Assert
    expect(find.text('会員ログイン'), findsOneWidget);
    expect(find.byType(EmailPasswordLoginForm), findsOneWidget);
    expect(find.byType(GoogleLoginButton), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
  });

  testWidgets('back button navigates correctly', (tester) async {
    // Arrange
    await tester.pumpWidget(MaterialApp(
      home: LoginPage(),
      routes: {'/previous': (context) => Container()},
    ));
    
    // Act
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    
    // Assert
    // Navigation verification logic
  });
});
```

#### 4.1.2 ローディング状態テスト

```dart
testWidgets('displays loading indicator when loading', (tester) async {
  // Arrange
  await tester.pumpWidget(MaterialApp(home: LoginPage()));
  
  // Simulate loading state
  // This would require exposing loading state or using a test-specific setup
  
  // Assert
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.byType(ColoredBox), findsOneWidget); // Overlay
});
```

### 4.2 EmailPasswordLoginForm テスト

#### 4.2.1 フォーム入力テスト

```dart
group('EmailPasswordLoginForm Widget Tests', () {
  testWidgets('validates email input correctly', (tester) async {
    // Arrange
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EmailPasswordLoginForm(
          authService: MockAuthService(),
          onLoginSuccess: () {},
          onLoadingStateChanged: (_) {},
          showSnackBar: (_) {},
        ),
      ),
    ));
    
    // Act - Empty input
    await tester.tap(find.byKey(Key('login_form_email')));
    await tester.pump();
    
    // Submit form to trigger validation
    // Implementation depends on form structure
    
    // Assert
    expect(find.text('メールアドレスを入力してください'), findsOneWidget);
  });

  testWidgets('validates password input correctly', (tester) async {
    // Similar structure for password validation
  });
});
```

#### 4.2.2 パスワード表示切り替えテスト

```dart
testWidgets('toggles password visibility', (tester) async {
  // Arrange
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: EmailPasswordLoginForm(/* ... */),
    ),
  ));
  
  final passwordField = find.byKey(Key('login_form_password'));
  final visibilityIcon = find.byIcon(Icons.visibility);
  
  // Act
  await tester.tap(visibilityIcon);
  await tester.pump();
  
  // Assert
  expect(find.byIcon(Icons.visibility_off), findsOneWidget);
});
```

#### 4.2.3 ログインボタン状態テスト

```dart
testWidgets('login button enabled when form is valid', (tester) async {
  // Arrange
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: EmailPasswordLoginForm(/* ... */),
    ),
  ));
  
  // Act - Fill in valid data
  await tester.enterText(find.byKey(Key('login_form_email')), 'test@example.com');
  await tester.enterText(find.byKey(Key('login_form_password')), 'password123');
  await tester.pump();
  
  // Assert
  final loginButton = tester.widget<FilledButton>(find.byType(FilledButton));
  expect(loginButton.onPressed, isNotNull);
});

testWidgets('login button disabled when form is invalid', (tester) async {
  // Arrange
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: EmailPasswordLoginForm(/* ... */),
    ),
  ));
  
  // Act - Leave fields empty
  await tester.pump();
  
  // Assert
  final loginButton = tester.widget<FilledButton>(find.byType(FilledButton));
  expect(loginButton.onPressed, isNull);
});
```

### 4.3 GoogleLoginButton テスト

```dart
group('GoogleLoginButton Widget Tests', () {
  testWidgets('displays Google logo and text', (tester) async {
    // Arrange
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GoogleLoginButton(
          authService: MockAuthService(),
          isLoading: false,
          email: null,
          onLoginSuccess: () {},
          onLoadingStateChanged: (_) {},
          showSnackBar: (_) {},
        ),
      ),
    ));
    
    // Assert
    expect(find.text('Googleログイン'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('button disabled when loading', (tester) async {
    // Arrange
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GoogleLoginButton(
          authService: MockAuthService(),
          isLoading: true,
          email: null,
          onLoginSuccess: () {},
          onLoadingStateChanged: (_) {},
          showSnackBar: (_) {},
        ),
      ),
    ));
    
    // Assert
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
});
```

### 4.4 ResetPasswordLink テスト

```dart
group('ResetPasswordLink Widget Tests', () {
  testWidgets('displays underlined text', (tester) async {
    // Arrange
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ResetPasswordLink()),
    ));
    
    // Assert
    expect(find.text('パスワードをお忘れの方'), findsOneWidget);
    
    final textWidget = tester.widget<Text>(find.text('パスワードをお忘れの方'));
    expect(textWidget.style?.decoration, TextDecoration.underline);
  });
});
```

## 5. 統合テスト仕様

### 5.1 メール・パスワード認証フロー統合テスト

```dart
group('Email Password Authentication Integration Tests', () {
  testWidgets('complete login flow with valid credentials', (tester) async {
    // Arrange
    await tester.pumpWidget(MyApp()); // Full app widget
    await tester.pumpAndSettle();
    
    // Navigate to login page
    // Implementation depends on app structure
    
    // Act
    await tester.enterText(find.byKey(Key('login_form_email')), 'test@example.com');
    await tester.enterText(find.byKey(Key('login_form_password')), 'password123');
    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle();
    
    // Assert
    // Verify navigation to home screen
    expect(find.byType(Home), findsOneWidget);
  });

  testWidgets('login flow with invalid credentials shows error', (tester) async {
    // Arrange
    await tester.pumpWidget(MyApp());
    
    // Mock auth service to return error
    
    // Act
    await tester.enterText(find.byKey(Key('login_form_email')), 'invalid@example.com');
    await tester.enterText(find.byKey(Key('login_form_password')), 'wrongpassword');
    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle();
    
    // Assert
    expect(find.text('認証処理に失敗しました(メールアドレス)'), findsOneWidget);
  });
});
```

### 5.2 Google OAuthフロー統合テスト

Google OAuthはブラウザを起動して外部サービスと通信するため、
ウィジェットテストでのエンドツーエンド検証は困難です。
以下の観点で分割してテストします。

**ウィジェットテストで検証可能な範囲**:
```dart
group('GoogleLoginButton OAuth Tests', () {
  testWidgets('Googleログインボタンタップ後にローディングが開始・解除される', (tester) async {
    // Arrange
    final mockAuthService = MockAuthService();
    when(mockAuthService.signInWithGoogleOAuth())
        .thenAnswer((_) async {}); // ブラウザ起動をモック

    await tester.pumpWidget(createTestWidget(
      child: GoogleLoginButton(
        authService: mockAuthService,
        isLoading: false,
        email: null,
        onLoginSuccess: () async {},
        onLoadingStateChanged: (_) {},
        showSnackBar: (_) {},
      ),
    ));

    // Act
    await tester.tap(find.text('Googleログイン'));
    await tester.pump();

    // Assert: signInWithGoogleOAuth が呼ばれたことを確認
    verify(mockAuthService.signInWithGoogleOAuth()).called(1);
  });
});
```

**E2Eテストで検証する範囲**:
- 実際のブラウザでのGoogle認証
- OAuthコールバックURIのディープリンク受信
- `_handleOAuthCallback()` によるセッション確立とHome画面遷移

### 5.3 自動認証テスト

```dart
group('Auto Authentication Integration Tests', () {
  testWidgets('auto navigates when already authenticated', (tester) async {
    // Arrange
    // Mock authenticated state
    
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();
    
    // Assert
    expect(find.byType(Home), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });
});
```

## 6. モックとテストダブル

### 6.1 必要なモック

```dart
// AuthService モック
class MockAuthService extends Mock implements AuthService {}

// Supabase モック
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

// Firebase Messaging モック
class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}
```

**注**: `google_sign_in` パッケージは使用していないため、
`MockGoogleSignIn`, `MockGoogleSignInAccount`, `MockGoogleSignInAuthentication` は不要です。
Google認証は Supabase OAuth 経由でブラウザを起動するため、
`MockAuthService` の `signInWithGoogleOAuth()` のみをモックします。

### 6.2 テスト用ウィジェット

```dart
Widget createTestWidget({
  required Widget child,
  AuthService? authService,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Provider<AuthService>(
        create: (_) => authService ?? MockAuthService(),
        child: child,
      ),
    ),
  );
}
```

## 7. テストデータ

### 7.1 有効なテストデータ

```dart
class TestData {
  static const validEmail = 'test@example.com';
  static const validPassword = 'password123';
  static const mockUserId = 'user123';
  static const mockFcmToken = 'mock_fcm_token';
  
  static User createMockUser({
    String? id,
    String? email,
  }) {
    final mockUser = MockUser();
    when(mockUser.id).thenReturn(id ?? mockUserId);
    when(mockUser.email).thenReturn(email ?? validEmail);
    return mockUser;
  }
}
```

### 7.2 無効なテストデータ

```dart
class InvalidTestData {
  static const emptyEmail = '';
  static const emptyPassword = '';
  static const invalidEmail = 'invalid-email';
  static const shortPassword = '123';
}
```

## 8. パフォーマンステスト

### 8.1 ローディング時間テスト

```dart
group('Performance Tests', () {
  testWidgets('login form renders within acceptable time', (tester) async {
    final stopwatch = Stopwatch()..start();
    
    await tester.pumpWidget(MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();
    
    stopwatch.stop();
    
    expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 1秒以内
  });
});
```

### 8.2 メモリリークテスト

```dart
testWidgets('no memory leaks in login page', (tester) async {
  // Multiple creation and disposal cycles
  for (int i = 0; i < 10; i++) {
    await tester.pumpWidget(MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();
    
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  }
  
  // Memory usage verification would require additional tooling
});
```

## 9. テスト実行とCI/CD統合

### 9.1 テスト実行コマンド

```bash
# すべてのテスト実行
flutter test

# 特定のテストファイル実行
flutter test test/signin/auth_service_test.dart

# ウィジェットテストのみ
flutter test test/widget/

# 統合テストのみ  
flutter test test/integration/

# カバレッジ付きテスト実行
flutter test --coverage
```

### 9.2 CI/CD設定例

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.8.0'
      - run: flutter pub get
      - run: flutter test --coverage
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v1
```

## 10. テストカバレッジ目標

### 10.1 カバレッジ基準

| テストタイプ | 目標カバレッジ | 最低カバレッジ |
|-------------|--------------|---------------|
| 単体テスト | 90% | 80% |
| ウィジェットテスト | 85% | 75% |
| 統合テスト | 70% | 60% |
| 全体 | 85% | 75% |

### 10.2 重要機能の100%カバレッジ対象

- 認証処理関数
- バリデーション関数
- エラーハンドリング
- セキュリティ関連処理

## 11. テストメンテナンス

### 11.1 定期的なテスト見直し

- 新機能追加時のテスト追加
- 既存テストの有効性確認
- テストデータの更新
- モックの更新

### 11.2 テスト品質指標

- テスト実行時間の監視
- フレイキーテストの特定と修正
- テストカバレッジの維持
- テストコードの保守性