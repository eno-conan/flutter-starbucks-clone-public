import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testingapp/provider/selected_tab_provider.dart';

void main() {
  group('SelectedTabNotifier', () {
    test('初期値が0であること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final result = container.read(selectedTabProvider);

      // Assert
      expect(result, 0);
    });

    test('setTabで選択タブが更新されること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      container.read(selectedTabProvider.notifier).setTab(3);

      // Assert
      expect(container.read(selectedTabProvider), 3);
    });

    test('setTabを複数回呼び出すと最後に設定した値になること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      container.read(selectedTabProvider.notifier).setTab(2);
      container.read(selectedTabProvider.notifier).setTab(4);
      container.read(selectedTabProvider.notifier).setTab(1);

      // Assert
      expect(container.read(selectedTabProvider), 1);
    });
  });
}
