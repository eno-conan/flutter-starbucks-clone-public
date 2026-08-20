import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testingapp/shared/widgets/texts/my_custom_text.dart';

void main() {
  group('MyCustomText', () {
    testWidgets('指定したテキストが表示されること', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(home: MyCustomText(text: 'テストボタン')),
      );

      // Assert
      expect(find.text('テストボタン'), findsOneWidget);
    });

    testWidgets('オプション未指定の場合はデフォルトスタイルが適用されること', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(home: MyCustomText(text: 'デフォルト')),
      );
      final textWidget = tester.widget<Text>(find.text('デフォルト'));

      // Assert
      expect(textWidget.style?.fontSize, MyCustomText.defaultFontSize);
      expect(textWidget.style?.color, MyCustomText.defaultTextColor);
      expect(textWidget.style?.fontWeight, MyCustomText.defaultFontWeight);
      expect(textWidget.style?.fontFamily, 'NotoSansJP');
      expect(textWidget.style?.decoration, TextDecoration.none);
      expect(textWidget.textAlign, MyCustomText.defaultTextAlign);
      expect(textWidget.softWrap, MyCustomText.defaultSoftWrap);
    });

    testWidgets('fontSize・textColor・fontWeightを指定すると反映されること', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: MyCustomText(
            text: 'カスタム',
            fontSize: 20,
            textColor: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      final textWidget = tester.widget<Text>(find.text('カスタム'));

      // Assert
      expect(textWidget.style?.fontSize, 20);
      expect(textWidget.style?.color, Colors.red);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('useEnglishFontをtrueにするとRobotoフォントが使われること', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(home: MyCustomText(text: 'English', useEnglishFont: true)),
      );
      final textWidget = tester.widget<Text>(find.text('English'));

      // Assert
      expect(textWidget.style?.fontFamily, 'Roboto');
    });

    testWidgets('isUnderlineをtrueにすると下線が付与されること', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(home: MyCustomText(text: '下線', isUnderline: true)),
      );
      final textWidget = tester.widget<Text>(find.text('下線'));

      // Assert
      expect(textWidget.style?.decoration, TextDecoration.underline);
    });
  });
}
