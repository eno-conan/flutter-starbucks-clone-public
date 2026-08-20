import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testingapp/config/app_initializer.dart';
import 'package:testingapp/config/app_router.dart';
import 'package:testingapp/screens/starbucks_user_side/gift/gift_screen.dart';

/// Giftタブをテストするための最小アプリ。
/// AppRouter.routes を再利用するため StatefulShellRoute が正しく解決される。
Widget buildGiftTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(initialLocation: Gift.routeName, routes: AppRouter.routes),
  ),
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    // Firebase・Supabase・Google Sign-In の初期化(1回のみ)
    await AppInitializer.initializeApp();
  });

  group('Giftタブ - 表示内容', () {
    testWidgets('ヘッダーとeGift・Digital Cardセクションが表示されること', (tester) async {
      await tester.pumpWidget(buildGiftTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 「Gift」はボトムナビのタブラベルとしても表示されるため、
      // FixedHeaderCommonComponentのヘッダー(fontSize:28)であることまで絞り込んで判定する。
      final headerFinder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'Gift' && widget.style?.fontSize == 28,
      );
      expect(headerFinder, findsOneWidget, reason: 'Giftヘッダーが見つかりません');
      expect(find.text('Starbucks eGift'), findsOneWidget);
      expect(find.text('eGiftを贈る'), findsOneWidget);
      expect(find.text('Digital Card Gift'), findsOneWidget);
      expect(find.text('Digital Cardを贈る'), findsOneWidget);
    });
  });
}
