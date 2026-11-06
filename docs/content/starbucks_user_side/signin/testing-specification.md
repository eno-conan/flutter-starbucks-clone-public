# ログイン機能 テスト仕様書

## 1. テスト概要

- 目的: ログイン機能の品質を保証する。
- 実装するテスト: 単体テスト、ウィジェットテスト、統合テスト。
- 検証すること: 各認証フローの正常動作と、エラーハンドリング。

!!! tip "読み方"
    - 各テストのコード例は、折り畳み（`コード例`）の中にある。
    - 方針と範囲だけ読むなら、折り畳みを開かずに最後まで読める。

### 1.1 実在するテスト

- 2026-10 時点の、ログイン関連のテスト。件数は `test(` / `testWidgets(` の呼び出し数。

| 対象 | ファイル | 件数 | 確認していること |
|---|---|---|---|
| `LoginPage` | `test/screens/starbucks_user_side/signin/login_page_test.dart` | 4 | 並び順（パスキーあり: パスキー→Google→メール / なし: Google→メール）、メール・パスワード欄のキー、キーボード表示時にメール欄が見える（360x640） |
| `GoogleLoginButton` | `test/screens/starbucks_user_side/signin/google_login_button_test.dart` | 2 | 白背景で文字が白以外であること、背景が白のままであること |
| `PasskeyLoginButton` | `test/screens/starbucks_user_side/signin/widgets/passkey_login_button_test.dart` | 1 | 金色の背景の上で、文字とアイコンが読めるコントラストで表示されること |
| `AuthService` | `test/services/auth_service_test.dart` | 5 | `purgeLegacyCredentials`（旧キーだけを削除する、キーが無くても例外を出さない、削除に失敗しても例外を出さない）と、`signOutWithEmailAndPassword`（サインアウトの前にこの端末の FCM トークンを空にする、空にできなくてもサインアウトは続行する） |
| `PasskeyAuthService` | `test/services/passkey_auth_service_test.dart` | 18 | `signIn` / `register` / `list` / `delete` / `isAvailable`、失敗種別への変換と表示文言（1 件は種別ごとに繰り返す） |
| `PasskeyPromptPolicy` | `test/services/passkey_prompt_policy_test.dart` | 11 | 登録提案の間隔（7 日 → 30 日 → 3 回で停止） |
| ホーム画面のパスキー登録提案 | `test/screens/starbucks_user_side/home/home_passkey_prompt_test.dart` | 3 | 提案の判定に入るのは `signedIn`（ログイン成功）だけで、`initialSession`（起動時のセッション復元）・`tokenRefreshed`・`userUpdated` では入らない |
| `FcmTokenSyncService` | `test/services/fcm_token_sync_service_test.dart` | 12 | ログイン後の FCM トークン登録 |
| ログインフロー（統合） | `integration_test/login_flow_cases.dart` | 3 | フォーム表示 / 誤ったパスワードで画面にとどまる / 正しい認証で Home へ遷移 |

- 統合テスト（`integration_test/`）は、CI では実行しない。手元の実機・エミュレータで実行する。
- 統合テストはメール・パスワードだけ。Google とパスキーのログインは、自動テストが無い。

!!! warning "2 章以降のコード例は、設計時のサンプル"
    - 2 章以降のコード例は、テストを設計したときのサンプル。同名のテストが存在するとは限らない。
    - 実在するテストは、上の表を正とする。食い違うときは、表（とテストコード）が正。
    - 次のサンプルは、まだ書かれていない: `AuthService` の認証状態・ユーザー取得・メール認証・FCM のテスト、`EmailPasswordLoginForm` / `ResetPasswordLink` のウィジェットテスト、`PasskeyLoginButton` と `GoogleLoginButton` の表示・タップ・ローディング中の無効化（実在のテストは配色だけ）、Google ログインのコールバック。
    - サンプルの `LoginPage()` は、`ProviderScope` と Provider の差し替えが無いと動かない。実在のテストは `login_page_test.dart` を参照。

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

??? example "コード例（31 行）"
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

??? example "コード例（25 行）"
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

??? example "コード例（23 行）"
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

??? example "コード例（28 行）"
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

- `signInWithGoogleOAuth()` はブラウザを起動する外部呼び出し。
- そのため、ユニットテストでは `supabase.auth.signInWithOAuth()` の呼び出しを検証する。

- `redirectTo` は debug / release 共通で `testingapp://callback`。`kDebugMode` による切り替えはないため、モードごとのテストは要らない。

??? example "コード例（18 行・サンプル）"
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
    });
    ```

!!! warning "方針: OAuth のブラウザ後の処理は E2E で検証する"
    - ブラウザ起動後の実際の OAuth 認証フローは、外部ブラウザを伴う。
    - そのため、ウィジェットテストでの自動検証が困難。
    - OAuth 認証後のコールバック処理（`_handleOAuthCallback`）は、E2E テストで検証する。

### 3.3 FCMトークン管理テスト

??? example "コード例（44 行）"
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

??? example "コード例（27 行）"
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

??? example "コード例（11 行）"
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

??? example "コード例（29 行）"
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

??? example "コード例（18 行）"
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

??? example "コード例（33 行）"
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

??? example "コード例（41 行）"
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

??? example "コード例（14 行）"
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

??? example "コード例（36 行）"
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

- Google OAuth はブラウザを起動して外部サービスと通信する。
- そのため、ウィジェットテストでのエンドツーエンド検証は困難。
- 次の 2 つの観点に分けてテストする。

**ウィジェットテストで検証可能な範囲**:

??? example "コード例（26 行）"
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
- `_handleOAuthCallback()` によるセッション確立の確認とHome画面遷移

!!! warning "この範囲の自動テストは、まだ無い"
    - `integration_test/login_flow_cases.dart` は、メール・パスワードのケースだけ。
    - Google ログインは、実機での手動確認になる。

### 5.3 自動認証テスト

??? example "コード例（13 行）"
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

??? example "コード例（10 行）"
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

!!! note "Google 関連のモックは `signInWithGoogleOAuth()` だけ"
    - `google_sign_in` パッケージは使用していない。
    - よって `MockGoogleSignIn`・`MockGoogleSignInAccount`・`MockGoogleSignInAuthentication` は不要。
    - Google 認証は Supabase OAuth 経由でブラウザを起動する。
    - そのため、`MockAuthService` の `signInWithGoogleOAuth()` だけをモックする。

### 6.2 テスト用ウィジェット

??? example "コード例（13 行）"
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

??? example "コード例（16 行）"
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

??? example "コード例（12 行）"
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

??? example "コード例（12 行）"
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
# すべての単体・Widget テスト（失敗ダイジェスト付き。CI と同じ）
bash scripts/run-tests.sh

# ログイン画面のテストだけ
bash scripts/run-tests.sh test/screens/starbucks_user_side/signin

# 特定のテストファイル
flutter test test/services/auth_service_test.dart
flutter test test/services/passkey_auth_service_test.dart

# 統合テスト（実機またはエミュレータが必要）
bash scripts/run-tests.sh integration_test/
```

### 9.2 CI

- PR・main への push: `test.yml` が、`dart analyze` と `scripts/run-tests.sh`（単体・Widget テスト）を実行する。
- 統合テスト: CI では実行しない。手元の実機・エミュレータで実行する（[統合テストガイド](../../flutter/integration-test-guide.md)）。
- トリガーや Secrets の詳細は、[CI/CD](../../release/cicd.md) を参照。

## 10. テストカバレッジ目標

### 10.1 カバレッジ基準

!!! note "目標値であり、CI で強制していない"
    - `.github/workflows/` に、カバレッジを測る・閾値で失敗させる処理は無い。

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