import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testingapp/config/app_initializer.dart';
import 'package:testingapp/config/app_router.dart';
import 'package:testingapp/screens/starbucks_user_side/rewards/rewards_screen.dart';

/// スターリワード画面をテストするための最小アプリ。
Widget buildRewardsTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(initialLocation: Rewards.routeName, routes: AppRouter.routes),
  ),
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    // Firebase・Supabase・Google Sign-In の初期化(1回のみ)
    await AppInitializer.initializeApp();
  });

  group('スターリワード画面 - 表示内容', () {
    testWidgets('ヘッダーと各セクションが表示されること', (tester) async {
      await tester.pumpWidget(buildRewardsTestApp());
      // getTotalPointsWithExpirationFlagZero RPC の解決を待つ
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.text('Rewards'), findsOneWidget, reason: 'Rewardsヘッダーが見つかりません');
      expect(find.text('ご利用ガイド'), findsOneWidget);
      expect(find.text('お買い物54円(税込)あたり、starが1つたまります。'), findsOneWidget);
      expect(find.text('スターリワードに交換'), findsOneWidget);
      expect(find.text('保有Starの有効期限'), findsOneWidget);
      expect(find.text('会員ステータス'), findsOneWidget);
    });
  });
}
