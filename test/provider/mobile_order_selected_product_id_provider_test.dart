import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testingapp/provider/mobile_order_selected_product_id_provider.dart';

void main() {
  group('SelectedProductNotifier', () {
    test('初期値がSelectedProduct.emptyであること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      final result = container.read(selectedProductProvider);

      // Assert
      expect(result.id, SelectedProduct.empty.id);
      expect(result.imageUrl, SelectedProduct.empty.imageUrl);
    });

    test('selectProductで商品IDと画像URLが更新されること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Act
      container.read(selectedProductProvider.notifier).selectProduct('42', 'https://example.com/a.png');

      // Assert
      final result = container.read(selectedProductProvider);
      expect(result.id, '42');
      expect(result.imageUrl, 'https://example.com/a.png');
    });

    test('clearで選択状態がSelectedProduct.emptyに戻ること', () {
      // Arrange
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedProductProvider.notifier).selectProduct('42', 'https://example.com/a.png');

      // Act
      container.read(selectedProductProvider.notifier).clear();

      // Assert
      final result = container.read(selectedProductProvider);
      expect(result.id, SelectedProduct.empty.id);
      expect(result.imageUrl, SelectedProduct.empty.imageUrl);
    });
  });

  group('SelectedProduct.copyWith', () {
    test('引数を指定しない場合は同じ値のインスタンスを返すこと', () {
      // Arrange
      const original = SelectedProduct(id: '1', imageUrl: 'https://example.com/a.png');

      // Act
      final result = original.copyWith();

      // Assert
      expect(result.id, original.id);
      expect(result.imageUrl, original.imageUrl);
    });

    test('指定したフィールドのみが更新されること', () {
      // Arrange
      const original = SelectedProduct(id: '1', imageUrl: 'https://example.com/a.png');

      // Act
      final result = original.copyWith(id: '2');

      // Assert
      expect(result.id, '2');
      expect(result.imageUrl, original.imageUrl);
    });
  });
}
