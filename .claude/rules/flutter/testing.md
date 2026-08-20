---
description: テスト実装ガイドライン(単体・Widget・統合テスト)
paths:
  - "test/**/*_test.dart"
  - "integration_test/**/*_test.dart"
  - "integration_test/**/*_cases.dart"
---

# テスト実装ガイドライン

## 適用範囲

- **単体テスト・Widgetテスト**: `test/` 配下（本ファイルが構成・命名・モック方針の正）
- **統合テスト**: `integration_test/` 配下。具体的な実装パターン（AuthHelper・認証済みテストアプリの構築等）は
  `.claude/skills/integration-test/SKILL.md` を参照し、本ファイルではプロジェクト共通の命名・集約ルールのみを定義する

---

## テスト構成原則

1. **AAA パターン**: Arrange, Act, Assert の順序で実装
2. **独立性**: 各テストは独立して実行可能であること（他テストの実行順序に依存しない）
3. **可読性**: テスト名は実装内容を明確に表現する
4. **外部依存の排除**: Supabase・HTTPクライアント等の外部依存は必ずmock化し、実際のネットワーク呼び出しを行わない
   （実ネットワーク呼び出しが必要な検証は統合テストで行う）

---

## `test/` ディレクトリ構成（`lib/` をミラーする）

`test/` は `lib/` と同じ階層構造を持たせる。対象ファイルがどこにあるかで置き場所を判断できるようにし、
「実装 ⇄ テスト」の対応を一目で分かるようにする。

```
lib/                                    test/
├── core/                               ├── core/
│   ├── models/                         │   ├── models/
│   └── services/                       │   └── services/
├── data/repository/                    ├── data/repository/
├── provider/                           ├── provider/
├── screens/                            ├── screens/
│   └── starbucks_user_side/            │   └── starbucks_user_side/
│       └── pay/                        │       └── pay/
├── services/                           ├── services/
│   └── mobile_order_pay/               │   └── mobile_order_pay/
├── shared/                             ├── shared/
│   ├── helpers/                        │   ├── helpers/
│   └── widgets/                        │   └── widgets/
└── utils/                              └── utils/
```

`test/` 直下には共通テストヘルパー（`ProviderContainer` 生成補助、共通Fake/Mock等）を置く
`test/helpers/` を作成してよい。これは `lib/` に対応物がないため唯一の例外とする。

### テストファイル命名規則

対象ファイル名に `_test.dart` を付与する。

| 実装ファイル | テストファイル |
|---|---|
| `lib/utils/sanitization_utils.dart` | `test/utils/sanitization_utils_test.dart` |
| `lib/provider/selected_tab_provider.dart` | `test/provider/selected_tab_provider_test.dart` |
| `lib/data/repository/campaign_repository.dart` | `test/data/repository/campaign_repository_test.dart` |
| `lib/services/mobile_order_pay/order_validation_service.dart` | `test/services/mobile_order_pay/order_validation_service_test.dart` |
| `lib/screens/starbucks_user_side/pay/pay_screen.dart` | `test/screens/starbucks_user_side/pay/pay_screen_test.dart` |

### `group` / `test` 名の付け方

```dart
// ✅ 良い例: 分かりやすいテスト名
void main() {
  group('OrderValidationService', () {
    group('validateStoreStatus', () {
      test('営業中の店舗ではValidationSuccessを返すこと', () {
        // テスト実装
      });

      test('閉店15分前以降の場合はStoreClosingSoonを返すこと', () {
        // テスト実装
      });

      test('店舗情報が取得できない場合はValidationErrorを返すこと', () {
        // テスト実装
      });
    });
  });
}
```

- `group` はクラス名 → メソッド名の順にネストする
- `test` 名は日本語で「〜こと」で終える形式に統一する（既存の統合テストと合わせる）

---

## モックライブラリ: `mocktail` に統一

本プロジェクトの新規テストは **mocktail** を使用する。**mockito は使用しない**。

- 理由: `mocktail` はコード生成（`build_runner`）が不要で、Supabase SDK のような複雑な型を持つ依存も
  `class MockXxx extends Mock implements Xxx {}` の1行でモック化できる。テスト追加のたびに
  codegen を挟む必要がないため、テストコードを増やしていくフェーズと相性が良い。
- `pubspec.yaml` の `dev_dependencies` には現在 `mockito` と `mocktail` が両方存在するが、
  `mockito` は未使用であり新規テストでは使わないこと。テスト実装が一定量進んだ段階で `mockito` を
  `pubspec.yaml` から削除する（このルール整備作業のスコープ外のため本ドキュメントでは変更しない）。

### mocktail の基本パターン

```dart
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockStoreRepository extends Mock implements StoreRepository {}

void main() {
  late MockStoreRepository storeRepository;
  late OrderValidationService service;

  setUp(() {
    storeRepository = MockStoreRepository();
    service = OrderValidationService(storeRepository);
  });

  test('営業中の店舗ではValidationSuccessを返すこと', () async {
    // Arrange
    when(() => storeRepository.getStoreClosingTime('12345'))
        .thenAnswer((_) async => someFarFutureTime);

    // Act
    final result = await service.validateStoreStatus('12345');

    // Assert
    expect(result, isA<ValidationSuccess>());
  });
}
```

- `any()` に enum・カスタムクラス等の複雑な引数型を渡す場合は、`setUpAll` で
  `registerFallbackValue(FakeXxx())` を登録してから使用する。
- `verify()` / `verifyNever()` で呼び出し回数・引数を検証する場合は Act の直後、Assert の一部として書く。

---

## Riverpod 3.0 のテストパターン

Provider・Notifier の実装ルールは `.claude/rules/flutter/riverpod-3-guidelines.md` に従う
（`StateNotifierProvider` は禁止、`NotifierProvider` を使用）。テストも同様に Notifier API を前提とする。

### Notifier 単体テスト

```dart
test('setTabで選択タブが更新されること', () {
  // Arrange
  final container = ProviderContainer();
  addTearDown(container.dispose);

  // Act
  container.read(selectedTabProvider.notifier).setTab(2);

  // Assert
  expect(container.read(selectedTabProvider), 2);
});
```

### 依存Providerをmock化するパターン（Repository/Service層のoverride）

```dart
test('mock化したStoreRepositoryを使ってstoreWaitTimeProviderをテストする', () async {
  // Arrange
  final mockRepo = MockStoreRepository();
  when(() => mockRepo.getStoreClosingTime(any()))
      .thenAnswer((_) async => closingTime);

  final container = ProviderContainer(
    overrides: [storeRepositoryProvider.overrideWithValue(mockRepo)],
  );
  addTearDown(container.dispose);

  // Act
  final result = await container.read(storeWaitTimeProvider.future);

  // Assert
  expect(result, isNotNull);
});
```

- `ProviderContainer` は必ず `addTearDown(container.dispose)` で破棄する
- `.state` への直接アクセスはテストコードでも行わない。Notifier に定義された専用メソッド
  （例: `setTab()`）を呼び出す

---

## Widget テストパターン

```dart
testWidgets('CustomButtonが正しいテキストを表示すること', (tester) async {
  // Arrange
  const testText = 'テストボタン';

  // Act
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // 必要な Provider を mock/fake で override する
      ],
      child: MaterialApp(home: CustomButton(text: testText)),
    ),
  );

  // Assert
  expect(find.text(testText), findsOneWidget);
});
```

- 画面全体のWidgetテストは、`lib/config/app_router.dart` の実ルーティングに依存させず、
  対象Widgetを直接 `pumpWidget` できる場合はそちらを優先する（起動が速く、依存が少ない）。
  ルーティングを含めた検証が必要な場合は統合テスト（`integration_test/`）で行う。
- Golden Test（画面のスナップショット比較）を実装する場合は `docs/zensical/docs/flutter/widget-golden-test-guide.md` を参照する。

---

## 統合テストとの命名・集約ルール

統合テストの詳細パターンは `.claude/skills/integration-test/SKILL.md` を参照。本ルールでは
プロジェクト全体で守るべき命名・集約ルールのみを定める。

- テストケースファイルは `<機能>_cases.dart`（例: `login_flow_cases.dart`, `pay_tab_cases.dart`）として
  `integration_test/` 直下に置く。ファイル自体は `main()` を持つが、単体では実行しない
- 新規ケースファイルを追加したら、必ず `integration_test/all_tests_test.dart` に `as` インポートし、
  `main()` 内で呼び出すこと（漏れると `flutter test integration_test/` の対象から外れる）

```dart
// integration_test/all_tests_test.dart
import 'home_mobileorder_tab_cases.dart' as home_mobileorder;
import 'login_flow_cases.dart' as login_flow;
import 'pay_tab_cases.dart' as pay_tab;
import 'new_feature_cases.dart' as new_feature; // 追加したケースファイル

void main() {
  login_flow.main();
  pay_tab.main();
  home_mobileorder.main();
  new_feature.main();
}
```

- 認証情報は `integration_test/test_config.dart`（`.gitignore` 対象）を使用する。
  雛形は `integration_test/test_config.dart.example` を参照

---

## テスト必須項目

1. **境界値テスト**: 正常系・異常系の両方をカバーする
2. **外部依存のmock化**: Supabase・Repository・Service等の外部依存は `mocktail` でmock化する
3. **非同期テスト**: `async`/`await` を適切に使用し、`Future` のエラーケース（例外throw）も検証する
4. **リソース管理**: `ProviderContainer` は `addTearDown(container.dispose)` で必ず破棄する

---

## 実行コマンド

```bash
# 単体・Widgetテスト全体
flutter test

# 特定のテストファイルのみ
flutter test test/services/mobile_order_pay/order_validation_service_test.dart

# カバレッジ計測
flutter test --coverage

# 統合テスト（全体）
flutter test integration_test/all_tests_test.dart

# 統合テスト（特定ケースファイルのみ実行したい場合）
flutter test integration_test/login_flow_cases.dart
```
