import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testingapp/config/app_initializer.dart';
import 'package:testingapp/config/app_router.dart';
import 'package:testingapp/screens/starbucks_user_side/signin/login.dart';

import 'helpers/auth_helper.dart';

/// ログインページからスタートする最小テスト用アプリ。
/// AppRouter.routes を再利用するため、ログイン後のホーム画面遷移も実際のルーティングで動作する。
Widget buildLoginTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(initialLocation: LoginPage.routeName, routes: AppRouter.routes),
  ),
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    // Firebase・Supabase・Google Sign-In の初期化（1回のみ）
    await AppInitializer.initializeApp();
  });

  group('ログインフロー', () {
    tearDown(() async {
      // 各テスト後にログアウトして認証状態をリセット
      // (このgroup内に限定する。main()直下だとall_tests_test.dartで結合された
      //  他ファイルの全テストにまで適用されるグローバルなtearDownになってしまい、
      //  例えばPayタブ・設定画面の「認証済み状態」テストがこのtearDownに巻き込まれて
      //  意図せずログアウトさせられる不具合の原因になっていた。詳細: Issue #915)
      await AuthHelper.logoutTestUser();
    });

    testWidgets('a. ログインフォームが表示されること', (tester) async {
      await tester.pumpWidget(buildLoginTestApp());
      // LoginPage の initState（生体認証初期化など）完了を待つ
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byKey(const Key('login_form_email')), findsOneWidget);
      expect(find.byKey(const Key('login_form_password')), findsOneWidget);
      expect(find.text('ログイン'), findsOneWidget);
    });

    testWidgets('c. メールアドレスが正しくパスワードが間違っている場合はログイン画面にとどまること', (tester) async {
      await tester.pumpWidget(buildLoginTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await AuthHelper.attemptLoginWithWrongPassword(tester);

      // ログイン画面にとどまっていることを確認
      expect(find.byKey(const Key('login_form_email')), findsOneWidget);
      expect(find.byKey(const Key('login_form_password')), findsOneWidget);
    });

    testWidgets('b. 正しいメールアドレスとパスワードでログインするとホーム画面に遷移すること', (tester) async {
      await tester.pumpWidget(buildLoginTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await AuthHelper.loginAsTestUser(tester);

      // ホーム画面確認: main.dart の _SliverAppBar に設定された ValueKey で検証
      expect(
        find.byKey(const ValueKey('top_page_sliver_app_bar')),
        findsOneWidget,
        reason: 'ホーム画面の SliverAppBar が見つかりません',
      );
    });
  });
}
