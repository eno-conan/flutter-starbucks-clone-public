import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testingapp/config/app_initializer.dart';
import 'package:testingapp/config/app_router.dart';
import 'package:testingapp/screens/starbucks_user_side/e_ticket/main.dart';

import 'helpers/auth_helper.dart';

/// eチケット画面をテストするための最小アプリ。
/// AppRouter.routes を再利用するため authStateProvider による表示切り替えが実際の実装で動作する。
Widget buildETicketTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(initialLocation: ETicket.routeName, routes: AppRouter.routes),
  ),
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    // Firebase・Supabase・Google Sign-In の初期化(1回のみ)
    await AppInitializer.initializeApp();
  });

  group('eチケット画面 - 認証状態による表示切り替え', () {
    group('a. 未認証状態', () {
      tearDown(() async {
        await AuthHelper.logoutTestUser();
      });

      testWidgets('ログインが必要な旨のメッセージが表示されること', (tester) async {
        await tester.pumpWidget(buildETicketTestApp());
        // authStateProviderの解決を待つ
        await tester.pumpAndSettle(const Duration(seconds: 10));

        expect(find.text('eticket'), findsOneWidget, reason: 'eチケットヘッダーが見つかりません');
        expect(find.text('ログインが必要です'), findsOneWidget);
      });
    });

    group('b. 認証済み状態', () {
      setUpAll(() async {
        await AuthHelper.loginOnce();
      });

      tearDownAll(() async {
        await AuthHelper.logoutTestUser();
      });

      testWidgets('eTicketヘッダーと3つのタブが表示されること', (tester) async {
        await tester.pumpWidget(buildETicketTestApp());
        // authStateProvider + チケット一覧取得の解決を待つ
        await tester.pumpAndSettle(const Duration(seconds: 10));

        expect(find.text('eTicket'), findsOneWidget, reason: 'eTicketヘッダーが見つかりません');
        expect(find.text('利用可能'), findsOneWidget);
        expect(find.text('利用開始日前'), findsOneWidget);
        expect(find.text('利用済み'), findsOneWidget);
      });
    });
  });
}
