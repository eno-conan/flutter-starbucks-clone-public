import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testingapp/config/app_initializer.dart';
import 'package:testingapp/config/app_router.dart';
import 'package:testingapp/screens/starbucks_user_side/inbox/main.dart';

/// Inbox画面をテストするための最小アプリ。
Widget buildInboxTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(initialLocation: InboxTopPage.routeName, routes: AppRouter.routes),
  ),
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    // Firebase・Supabase・Google Sign-In の初期化(1回のみ)
    await AppInitializer.initializeApp();
  });

  group('Inbox画面 - 表示内容', () {
    testWidgets('ヘッダーと2つのタブが表示されること', (tester) async {
      await tester.pumpWidget(buildInboxTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Inbox'), findsOneWidget, reason: 'Inboxヘッダーが見つかりません');
      expect(find.text("What's New"), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
      expect(find.text('タブ1のコンテンツ'), findsOneWidget, reason: '初期表示タブのコンテンツが見つかりません');
    });
  });
}
