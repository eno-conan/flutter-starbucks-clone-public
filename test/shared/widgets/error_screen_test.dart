import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testingapp/shared/widgets/error_screen.dart';

void main() {
  group('ErrorScreen', () {
    testWidgets('"Error: "に続けてエラーメッセージが表示されること', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(home: ErrorScreen(error: 'ネットワークに接続できません')),
      );

      // Assert
      expect(find.text('Error: ネットワークに接続できません'), findsOneWidget);
    });

    testWidgets('Scaffoldでラップされていること', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ErrorScreen(error: 'error')));

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
