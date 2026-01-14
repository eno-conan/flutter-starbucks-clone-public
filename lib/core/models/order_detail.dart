/// 注文詳細アイテムのモデルクラス
class OrderDetailItem {
  OrderDetailItem({
    required this.productId,
    required this.temperatureTypeId,
    required this.sizeId,
    required this.count,
    required this.subtotalWithoutTax,
  });
  final int productId;
  final int temperatureTypeId;
  final int sizeId;
  final int count;
  final int subtotalWithoutTax;

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'temperature_type_id': temperatureTypeId,
      'size_id': sizeId,
      'count': count,
      'subtotal_without_tax': subtotalWithoutTax,
    };
  }
}
