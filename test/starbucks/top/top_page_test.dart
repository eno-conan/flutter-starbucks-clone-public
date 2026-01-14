import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:testingapp/screens/starbucks_user_side/home/main.dart';

class MockGoRouter extends Mock implements GoRouter {}

Widget createScreen() => const ProviderScope(child: MaterialApp(home: Home()));

void main() {
  group('Home Widget Tests', () {
    // testWidgets('Golden Test for Widget', (WidgetTester tester) async {
    //   await loadFonts();

    //   // 画面のサイズを設定する
    //   tester.view.physicalSize = const Size(1179, 2556);

    //   // シャドウを有効にする
    //   debugDisableShadows = false;

    //   await tester.pumpWidget(createScreen());
    //   await expectLater(
    //     find.byType(Home),
    //     matchesGoldenFile('goldens/top_page.png'),
    //   );
    //   // シャドウの有効化を解除する
    //   debugDisableShadows = true;
    // }, tags: 'golden');
    testWidgets('AppBarが正しく表示されていること', (tester) async {
      // await tester.pumpWidget(createScreen());
      // // AppBarに関する検証
      // final sliverAppBar = find.byKey(ValueKey('top_page_sliver_app_bar'));
      // expect(sliverAppBar, findsOneWidget);
      // final textFinder = find.descendant(of: sliverAppBar, matching: find.text('こんばんは'));
      // expect(textFinder, findsOneWidget);
    });
    testWidgets('navigationSectionが正しく表示されていること', (tester) async {
      // await tester.pumpWidget(createScreen());
      // // navigationSectionに関する検証
      // final navigationSection = find.byKey(ValueKey('top_page_navigation_section'));
      // expect(navigationSection, findsOneWidget);
      // // 各アイコンの検証
      // final iconsFinder = find.descendant(of: navigationSection, matching: find.byType(Icon));
      // expect(iconsFinder, findsNWidgets(3));
      // // 複数の要素について検証したい場合
      // final actualIcons = iconsFinder.evaluate().map((element) => element.widget as Icon).toList();
      // expect(actualIcons[0].icon, Icons.confirmation_number_outlined);
      // // 2つ目のアイコンの検証
      // expect(actualIcons[1].icon, Icons.mail);
      // expect(actualIcons[1].color, Colors.green);
      // // 3つ目のアイコンの検証
      // expect(actualIcons[2].icon, Icons.settings);

      // // 各テキストの検証
      // final textsFinder = find.descendant(of: navigationSection, matching: find.byType(Text));
      // expect(textsFinder, findsNWidgets(2));
      // final actualTexts = textsFinder.evaluate().map((element) => element.widget as Text).toList();
      // expect(actualTexts[0].data, 'eTicket');
      // // 2つ目のアイコンの検証
      // expect(actualTexts[1].data, 'Inbox');
    });
  });
}
