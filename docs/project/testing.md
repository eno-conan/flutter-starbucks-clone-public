# テスト

https://codelabs.developers.google.com/codelabs/flutter-app-testing?hl=ja

上記リンクの内容にのっとり、以下テストの基本的な書き方を学習予定
- プロバイダの単体テスト
- ウィジェットのテスト
- 統合テスト
- パフォーマンステスト

## テスト実行
```sh
flutter test
flutter test test/x.dart
```

## カバレッジ出力
- [参考記事](https://fredgrott.medium.com/lcov-on-windows-7c58dda07080)
```bash
flutter test --coverage
perl %GENHTML% -o coverage\html coverage\lcov.info
```

## IconやTextの複数検証
あるKeyで取得した要素でIconが3つあり、各内容を検証したい。
```dart
final navigationSection =
          find.byKey(ValueKey('top_page_navigation_section'));
expect(navigationSection, findsOneWidget);
// 各アイコンの検証
final iconsFinder = find.descendant(
  of: navigationSection,
  matching: find.byType(Icon),
);
expect(iconsFinder, findsNWidgets(3));
// 複数の要素について検証したい場合
final actualIcons = iconsFinder
    .evaluate()
    .map((element) => element.widget as Icon)
    .toList();
expect(actualIcons[0].icon, Icons.confirmation_number_outlined);
// 2つ目のアイコンの検証
expect(actualIcons[1].icon, Icons.mail);
expect(actualIcons[1].color, Colors.green);
// 3つ目のアイコンの検証
expect(actualIcons[2].icon, Icons.settings);
```

## Golden test
- [大変参考になった記事](https://zenn.dev/and_ai/articles/03e4bd6736a24b)
- [タグ付けによる実行時間短縮](https://codewithandrea.com/tips/unit-widget-test-tags-flutter/)

テスト実行コマンド
```bash
flutter test --update-goldens --tags=golden
```
