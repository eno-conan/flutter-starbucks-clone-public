import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testingapp/config/app_initializer.dart';
import 'package:testingapp/config/app_router.dart';
import 'package:testingapp/screens/starbucks_user_side/map/main.dart';

/// Storeタブ(地図画面)をテストするための最小アプリ。
/// AppRouter.routes を再利用するため StatefulShellRoute(StatefulNavigationShell)が正しく解決される。
Widget buildStoreTestApp() => ProviderScope(
  child: MaterialApp.router(
    routerConfig: GoRouter(initialLocation: Store.routeName, routes: AppRouter.routes),
  ),
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    // Firebase・Supabase・Google Sign-In の初期化(1回のみ)
    await AppInitializer.initializeApp();
  });

  group('Storeタブ - 地図画面の表示', () {
    testWidgets('ヘッダーとGoogleMapが表示されること', (tester) async {
      await tester.pumpWidget(buildStoreTestApp());

      // 位置情報の許可ダイアログ・GoogleMapの初期化・店舗マーカー生成を待つ
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 「Stores」はボトムナビのタブラベルとしても表示されるため、
      // FixedHeaderCommonComponentのヘッダー(fontSize:28)であることまで絞り込んで判定する。
      final headerFinder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'Stores' && widget.style?.fontSize == 28,
      );
      expect(headerFinder, findsOneWidget, reason: 'Storesヘッダーが見つかりません');
      expect(find.byType(GoogleMap), findsOneWidget, reason: 'GoogleMapが表示されていません');
    });
  });
}
