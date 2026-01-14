// モデルクラス
// ignore_for_file: avoid_dynamic_calls

class ProductDetail {
  ProductDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.temperatureTypeList,
    required this.sizeList,
    required this.price,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    // LoggerService.info(json); // 確認用

    // temperatureTypeListの抽出を修正
    final List<String> temperatureTypeList =
        (json['product_temperature_types'] as List?)
            ?.map(
              (item) =>
                  (item['temperature_types'] as Map<String, dynamic>)['type_name']?.toString() ??
                  'Unknown',
            )
            .toList() ??
        [];

    // sizeListの抽出を修正
    final List<String> sizeList =
        (json['product_sizes'] as List?)
            ?.map(
              (item) =>
                  (item['sizes'] as Map<String, dynamic>)['size_name']?.toString() ?? 'Unknown',
            )
            .toList() ??
        [];

    // priceの抽出を修正
    final List<int> price =
        (json['product_sizes'] as List?)?.map((item) => item['price'] as int).toList() ?? [];

    return ProductDetail(
      id: json['product_id'] as int,
      name: json['product_name'] as String,
      description: json['description'] as String? ?? '',
      temperatureTypeList: temperatureTypeList,
      sizeList: sizeList,
      price: price,
    );
  }
  final int id;
  final String name;
  final String description;
  final List<String> temperatureTypeList;
  final List<String> sizeList;
  final List<int> price;

  @override
  String toString() {
    return 'ProductDetail(id: $id, name: $name, description: $description, '
        'temperatureTypes: $temperatureTypeList, '
        'sizes: $sizeList, '
        'prices: $price)';
  }
}
