---
description: テスト実装ガイドライン（単体・Widget・統合テスト）
---

# テスト実装ガイドライン

## 単体テスト・統合テスト専用ルール

このルールは以下のディレクトリのテストファイル作業時に適用されます:
- `test/`
- `integration_test/`
- 任意のディレクトリ下の`test/`

### テスト構成原則

1. **AAA パターン**: Arrange, Act, Assert の順序で実装
2. **独立性**: 各テストは独立して実行可能であること
3. **可読性**: テスト名は実装内容を明確に表現

### テストファイル構成

```
test/
  ├── unit/                    # 単体テスト
  │   ├── services/           # サービステスト
  │   ├── models/             # モデルテスト
  │   └── utils/              # ユーティリティテスト
  ├── widget/                 # Widgetテスト
  └── integration/            # 統合テスト
```

### テスト命名規則

```dart
// ✅ 良い例: 分かりやすいテスト名
void main() {
  group('UserService', () {
    group('getUserProfile', () {
      test('正常なユーザーIDでプロフィールを取得できること', () {
        // テスト実装
      });

      test('存在しないユーザーIDでExceptionがスローされること', () {
        // テスト実装
      });
    });
  });
}
```

### Riverpod テストパターン

```dart
// Providerのテスト
test('UserProfileProvider should return user data', () async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  // Act
  final userProfile = await container.read(userProfileProvider.future);

  // Assert
  expect(userProfile.name, 'Test User');
});
```

### Widget テストパターン

```dart
testWidgets('CustomButton displays correct text', (tester) async {
  // Arrange
  const testText = 'テストボタン';

  // Act
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: CustomButton(text: testText),
      ),
    ),
  );

  // Assert
  expect(find.text(testText), findsOneWidget);
});
```

### テスト必須項目

1. **境界値テスト**: 正常系・異常系の両方をカバー
2. **Mockオブジェクト**: 外部依存はmockを使用
3. **非同期テスト**: async/await を適切に使用
4. **リソース管理**: テスト後のクリーンアップを実装
