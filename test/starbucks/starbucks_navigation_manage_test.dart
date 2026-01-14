import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';

class MockGoRouter extends Mock implements GoRouter {}

Widget createScreen() => ProviderScope(child: MaterialApp(home: Container()));

void main() {
  group('StarbucksNavigationManage Widget Tests', () {
    testWidgets('BottomNavigationBarTabBuilderのテキストが正しく表示されていること', (tester) async {
      // await tester.pumpWidget(createScreen());
      // // NavigatotionBar自体の検証
      // final navigationBar = find.byKey(ValueKey('bottom_navigation_bar'));
      // expect(navigationBar, findsOneWidget);
      // // 各タブのテキスト確認
      // for (final entry in StarbucksNavigationManageConstants.labelList.asMap().entries) {
      //   final index = entry.key;
      //   final text = entry.value;
      //   final bottomNavigationTab = find.byKey(ValueKey('bottom_navigation_bar_$index'));
      //   expect(bottomNavigationTab, findsOneWidget);
      //   final textFinder = find.descendant(of: bottomNavigationTab, matching: find.text(text));
      //   expect(textFinder, findsOneWidget);
      // }
      // 他メニューのアイコンを検証
    });
    testWidgets('Homeタブの選択時（初期表示時）：各要素が正しく表示されていること', (tester) async {
      // await tester.pumpWidget(createScreen());
      // // 各アイコンの状態を検証（Homeだけfillされたiconであること）
      // final expectedIconList = List<IconData>.from(StarbucksNavigationManageConstants.iconList);
      // // Homeタブのアイコンを置換
      // expectedIconList[0] = Icons.star;
      // for (final entry in expectedIconList.asMap().entries) {
      //   final index = entry.key;
      //   final icon = entry.value;
      //   final bottomNavigationTab = find.byKey(ValueKey('bottom_navigation_bar_$index'));
      //   final iconFinder = find.descendant(of: bottomNavigationTab, matching: find.byIcon(icon));
      //   expect(iconFinder, findsOneWidget);
      // }
      // 他メニューのアイコンを検証
    });
  });
}
