import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testingapp/core/models/store_mobile_order.dart';
import 'package:testingapp/provider/mobile_order_selected_store_provider.dart';

void main() {
  group('SelectedStoreNotifier', () {
    test('初期値がnullであること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final result = container.read(selectedStoreProvider);

      // Assert
      expect(result, isNull);
    });

    test('storeセッターで選択店舗が更新されること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final store = StoreMobileOrder(storeNumber: '001', storeName: 'テスト店舗');

      // Act
      container.read(selectedStoreProvider.notifier).store = store;

      // Assert
      expect(container.read(selectedStoreProvider), store);
      expect(container.read(selectedStoreProvider.notifier).store, store);
    });

    test('clearで選択店舗がnullに戻ること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedStoreProvider.notifier).store = StoreMobileOrder(
        storeNumber: '001',
        storeName: 'テスト店舗',
      );

      // Act
      container.read(selectedStoreProvider.notifier).clear();

      // Assert
      expect(container.read(selectedStoreProvider), isNull);
    });

    test('isEmptyは店舗未選択の場合にtrueを返すこと', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act & Assert
      expect(container.read(selectedStoreProvider.notifier).isEmpty(), isTrue);
    });

    test('isEmptyは店舗選択済みの場合にfalseを返すこと', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedStoreProvider.notifier).store = StoreMobileOrder(
        storeNumber: '001',
        storeName: 'テスト店舗',
      );

      // Act & Assert
      expect(container.read(selectedStoreProvider.notifier).isEmpty(), isFalse);
    });
  });

  group('SelectedStoreReaderExtension', () {
    test('readSelectedStoreで選択店舗を読み取れること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final store = StoreMobileOrder(storeNumber: '001', storeName: 'テスト店舗');
      container.read(selectedStoreProvider.notifier).store = store;

      // Act & Assert
      expect(container.readSelectedStore(), store);
    });

    test('isSelectedStoreEmptyで未選択状態を判定できること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act & Assert
      expect(container.isSelectedStoreEmpty(), isTrue);
    });
  });
}
