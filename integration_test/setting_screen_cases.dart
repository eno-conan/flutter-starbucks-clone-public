import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testingapp/config/app_initializer.dart';
import 'package:testingapp/config/app_router.dart';
import 'package:testingapp/screens/starbucks_user_side/setting/main.dart';

import 'helpers/auth_helper.dart';

/// 設定画面をテストするための最小アプリ。
/// AppRouter.routes を再利用するため authStateProvider による表示切り替えが実際の実装で動作する。
Widget buildSettingTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(initialLocation: Setting.routeName, routes: AppRouter.routes),
  ),
);

/// SliverListの最後尾までジャンプして表示させる。
///
/// `scrollUntilVisible`(ドラッグを繰り返す実装)は、ドラッグのたびにScrollableを
/// finderで解決し直すため、そのタイミングでWidgetツリーが再構築されていると
/// `Bad state: No element` で失敗することがあった(リトライしても再現。調査記録: Issue #915)。
/// ScrollableStateを一度だけ取得し、ジェスチャーを介さず直接scroll位置を
/// 変更することで、この種のタイミング競合を根本的に避ける。
Future<void> _jumpToScrollableBottom(WidgetTester tester) async {
  final scrollableState = tester.state<ScrollableState>(find.byType(Scrollable));
  scrollableState.position.jumpTo(scrollableState.position.maxScrollExtent);
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    // Firebase・Supabase・Google Sign-In の初期化(1回のみ)
    await AppInitializer.initializeApp();
  });

  group('設定画面 - 認証状態による表示切り替え', () {
    group('a. 未認証状態', () {
      tearDown(() async {
        await AuthHelper.logoutTestUser();
      });

      testWidgets('会員向けメニューが表示されないこと', (tester) async {
        await tester.pumpWidget(buildSettingTestApp());
        // authStateProviderの解決を待つ
        await tester.pumpAndSettle(const Duration(seconds: 10));

        expect(find.text('設定'), findsOneWidget, reason: '設定ヘッダーが見つかりません');
        expect(find.text('アプリについて'), findsOneWidget);
        expect(find.text('ログインアカウント'), findsNothing);
        expect(find.text('ログアウト'), findsNothing);
      });
    });

    group('b. 認証済み状態', () {
      setUpAll(() async {
        await AuthHelper.loginOnce();
      });

      tearDownAll(() async {
        await AuthHelper.logoutTestUser();
      });

      testWidgets('会員向けメニューとログアウトボタンが表示されること', (tester) async {
        await tester.pumpWidget(buildSettingTestApp());
        await tester.pumpAndSettle(const Duration(seconds: 10));

        expect(find.text('設定'), findsOneWidget, reason: '設定ヘッダーが見つかりません');
        expect(find.text('ログインアカウント'), findsOneWidget);
        expect(find.text('会員情報について'), findsOneWidget);

        // ログアウトボタンはSliverListの最後尾にあり初期表示範囲外のため、
        // 表示されるまでスクロールしてから検証する
        await _jumpToScrollableBottom(tester);
        expect(find.text('ログアウト'), findsOneWidget);
      });
    });
  });
}
