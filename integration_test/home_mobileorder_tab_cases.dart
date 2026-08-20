import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testingapp/config/app_initializer.dart';
import 'package:testingapp/config/app_router.dart';
import 'package:testingapp/screens/starbucks_user_side/home/main.dart';
import 'package:testingapp/screens/starbucks_user_side/mobile_order_pay/mobileorder_tab_container.dart';

import 'helpers/auth_helper.dart';

/// ホーム画面から開始するテスト用アプリ。
/// AppRouter.routes を再利用するため MobileOrderTabContainer へのルート遷移も実際のルーティングで動作する。
Widget buildHomeTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(initialLocation: Home.routeName, routes: AppRouter.routes),
  ),
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    // Firebase・Supabase・Google Sign-In の初期化（1回のみ）
    await AppInitializer.initializeApp();
  });

  group('ホーム画面 - モバイルオーダーセクションのナビゲーション', () {
    // ─────────────────────────────────────────────────────────────────────────
    // a. 未ログイン: 常に _NoOrder が表示されるため「オーダーする」のみ検証
    // ─────────────────────────────────────────────────────────────────────────
    group('a. 未ログイン状態', () {
      tearDown(() async {
        await AuthHelper.logoutTestUser();
      });

      testWidgets('「オーダーする」ボタンをタップするとモバイルオーダータブ（4つ目）に遷移すること', (tester) async {
        await tester.pumpWidget(buildHomeTestApp());

        // HomeMobileOrderSection._loadData() + connectivityCheckProvider の解決を待つ
        // 未ログイン時: Supabase クエリが空または失敗 → _NoOrder が表示される
        await tester.pumpAndSettle(const Duration(seconds: 10));

        await tester.tap(find.text('オーダーする'));

        // go_router の画面遷移 + MobileOrderTabContainer の初期化を待つ
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(
          find.text(headerText),
          findsOneWidget,
          reason: 'モバイルオーダーヘッダー "$headerText" が見つかりません',
        );
      });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // b. ログイン済み: 当日注文の有無によって表示ボタンが変わるため条件分岐で検証
    //   - 「オーダーを見る」が表示 → タップして履歴詳細への遷移を確認
    //   - 「オーダーする」が表示   → タップしてモバイルオーダータブへの遷移を確認
    //   - どちらも表示されない     → テスト失敗
    // ─────────────────────────────────────────────────────────────────────────
    group('b. ログイン済み状態', () {
      setUpAll(() async {
        await AuthHelper.loginOnce();
      });

      tearDown(() async {
        await AuthHelper.logoutTestUser();
      });

      testWidgets('当日注文状態に応じたボタンをタップすると正しい画面に遷移すること', (tester) async {
        await tester.pumpWidget(buildHomeTestApp());

        // HomeMobileOrderSection._loadData() + authStateProvider の解決を待つ
        await tester.pumpAndSettle(const Duration(seconds: 10));

        final hasOrder = find.text('オーダーを見る').evaluate().isNotEmpty;

        if (hasOrder) {
          // _HasOrder 表示: 当日注文あり → 「オーダーを見る」をタップして履歴詳細へ
          await tester.tap(find.text('オーダーを見る'));

          // go_router の画面遷移 + RPC（getUserOrders）の解決を待つ
          await tester.pumpAndSettle(const Duration(seconds: 10));

          expect(find.text('履歴詳細'), findsOneWidget, reason: '履歴詳細ヘッダーが見つかりません');
        } else {
          // _NoOrder 表示: 当日注文なし → 「オーダーする」をタップしてタブへ
          await tester.tap(find.text('オーダーする'));

          // go_router の画面遷移 + MobileOrderTabContainer の初期化を待つ
          await tester.pumpAndSettle(const Duration(seconds: 5));

          expect(
            find.text(headerText),
            findsOneWidget,
            reason: 'モバイルオーダーヘッダー "$headerText" が見つかりません',
          );
        }
      });
    });
  });
}
