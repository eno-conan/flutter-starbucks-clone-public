class ProductForMobileOrder {
  ProductForMobileOrder({
    required this.id,
    required this.name,
    required this.temperatureTypeId,
    required this.temperatureTypeName,
    required this.sizeId,
    required this.sizeName,
    required this.price,
    required this.count,
  });

  final int id;
  final String name;
  final int temperatureTypeId;
  final String temperatureTypeName;
  final int sizeId;
  final String sizeName;
  final int price;
  final int count;

  // 数量を変更した新しいインスタンスを返すメソッド
  ProductForMobileOrder copyWithCount(int newCount) {
    return ProductForMobileOrder(
      id: id,
      name: name,
      temperatureTypeId: temperatureTypeId,
      temperatureTypeName: temperatureTypeName,
      sizeId: sizeId,
      sizeName: sizeName,
      price: price,
      count: newCount,
    );
  }

  @override
  String toString() {
    return 'ProductForMobileOrder{id: $id, name: $name, temperatureTypeId: $temperatureTypeId, temperatureTypeName: $temperatureTypeName, sizeId: $sizeId, sizeName: $sizeName, price: $price, count: $count}';
  }
}
