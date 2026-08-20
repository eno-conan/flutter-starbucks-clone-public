import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:testingapp/config/app_initializer.dart';
import 'package:testingapp/config/app_router.dart';
import 'package:testingapp/screens/starbucks_user_side/pay/pay_screen.dart';

import 'helpers/auth_helper.dart';

/// Payタブをテストするための最小アプリ。
/// AppRouter.routes を再利用するため StatefulShellRoute が正しく解決される。
Widget buildPayTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(initialLocation: Pay.routeName, routes: AppRouter.routes),
  ),
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    // Firebase・Supabase・Google Sign-In の初期化（1回のみ）
    await AppInitializer.initializeApp();
  });

  group('Payタブ - 認証状態による表示切り替え', () {
    group('a. 未認証状態', () {
      tearDown(() async {
        await AuthHelper.logoutTestUser();
      });

      testWidgets('未ログイン用UIが表示され、ログイン済みUIが非表示であること', (tester) async {
        await tester.pumpWidget(buildPayTestApp());
        // connectivityCheckProvider + authStateProvider の解決を待つ
        await tester.pumpAndSettle(const Duration(seconds: 10));

        expect(find.text('ご利用にはログインが必要です'), findsOneWidget);
        expect(find.text('残高更新'), findsNothing);
      });
    });

    group('b. 認証済み状態', () {
      setUpAll(() async {
        await AuthHelper.loginOnce();
      });

      tearDownAll(() async {
        await AuthHelper.logoutTestUser();
      });

      testWidgets('ログイン済みUIが表示され、未ログイン用UIが非表示であること', (tester) async {
        await tester.pumpWidget(buildPayTestApp());
        // connectivityCheckProvider + authStateProvider の解決を待つ
        await tester.pumpAndSettle(const Duration(seconds: 10));

        expect(find.text('残高更新'), findsOneWidget);
        expect(find.text('ご利用にはログインが必要です'), findsNothing);
      });

      testWidgets('ログイン済み：支払いFABタップ→支払い画面遷移・QRコード表示・コード番号ダイアログを確認', (tester) async {
        await tester.pumpWidget(buildPayTestApp());
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // FAB「支払い」をタップ
        await tester.tap(find.text('支払い'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // ① ヘッダーテキスト「支払い」が表示されること
        expect(find.text('支払い'), findsOneWidget);

        // ② QRコードが表示されること
        expect(find.byType(QrImageView), findsOneWidget);

        // ③ 「コード番号を表示」テキストが表示されること
        expect(find.text('コード番号を表示'), findsOneWidget);

        // ④ 「コード番号を表示」をタップ
        await tester.tap(find.text('コード番号を表示'));
        await tester.pumpAndSettle();

        // (1) ダイアログが表示される
        expect(find.byType(AlertDialog), findsOneWidget);

        // (2) 「コード番号」ラベルと、具体的なコードが表示される
        expect(find.text('コード番号'), findsOneWidget);
        expect(find.byType(SelectableText), findsAtLeastNWidgets(1));

        // (3) 「閉じる」をタップするとダイアログが消える
        await tester.tap(find.text('閉じる'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      });
    });
  });
}
