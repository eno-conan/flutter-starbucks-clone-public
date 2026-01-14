import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testingapp/app/menu.dart';

Widget createSettingScreen() => const ProviderScope(child: MaterialApp(home: MenuPage()));

void main() {
  group('メニュー画面のウィジェットテスト', () {
    // testWidgets('初期表示のテキスト表示', (tester) async {
    //   await tester.pumpWidget(createSettingScreen());
    //   final titleFinder = find.byType(CircularProgressIndicator);
    //   expect(titleFinder, findsOneWidget);
    // });

    // testWidgets('各メニューのアイコン・文言が想定通りであること', (tester) async {
    //   await tester.pumpWidget(createSettingScreen());
    //   for (final item in menuItems) {
    //     expect(find.byKey(Key('menu_item_${item.routeName}')),
    //         findsOneWidget);
    //     expect(find.text(item.label), findsOneWidget);
    //   }
    // });
  });
}
