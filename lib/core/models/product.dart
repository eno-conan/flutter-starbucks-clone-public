import 'package:intl/intl.dart';

final _formatter = NumberFormat('#,###');

// モデルクラス
class Product {
  Product({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.priceList,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // 金額に関する調整
    final List<dynamic> priceData = json['price'] as List<dynamic>;
    // ignore: avoid_dynamic_calls
    final List<int> priceList = priceData.map((item) => (item as num).toInt()).toList();
    return Product(
      id: json['product_id'] as int,
      name: json['product_name'] as String,
      imagePath: json['product_image_path'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category_name'] as String? ?? '',
      priceList: priceList,
    );
  }

  final int id;
  final String name;
  final String imagePath;
  String imageUrl;
  final String description;
  final String category;
  final List<int> priceList;

  // JSONに変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'product_id': id,
      'product_name': name,
      'product_image_path': imagePath,
      'image_url': imageUrl,
      'description': description,
      'category_name': category,
      'price': priceList,
    };
  }

  // 商品一覧画面の表示用フォーマット
  String get formattedPrice {
    if (priceList.length <= 1) {
      // サイズが1以下の場合の処理
      return priceList.isEmpty ? '¥0' : '¥${_formatter.format(priceList[0])}';
    } else {
      // サイズが2以上の場合の処理
      // 例：最小値と最大値を表示
      final int minPrice = priceList.reduce((a, b) => a < b ? a : b);
      final int maxPrice = priceList.reduce((a, b) => a > b ? a : b);
      return '¥${_formatter.format(minPrice)} ~ ¥${_formatter.format(maxPrice)}';
    }
  }

  @override
  String toString() {
    return 'Product('
        'id: $id, '
        'name: $name, '
        'imagePath: $imagePath, '
        'imageUrl: $imageUrl, '
        'description: $description, '
        'category: $category, '
        'priceList: $priceList'
        ')';
  }
}

// サンプル商品データ
final List<Product> sampleProducts = [
  Product(
    id: 1,
    name: 'アメリカーノ',
    imagePath: 'products/product_1.png',
    imageUrl: 'https://via.placeholder.com/200x200/4CAF50/FFFFFF?text=Coffee',
    description: 'シンプルなブラックコーヒー',
    category: 'コーヒー',
    priceList: [300, 350, 400],
  ),
  Product(
    id: 2,
    name: 'エスプレッソ',
    imagePath: 'products/product_2.png',
    imageUrl: 'https://via.placeholder.com/200x200/4CAF50/FFFFFF?text=Coffee',
    description: '濃厚なコーヒーショット',
    category: 'コーヒー',
    priceList: [250],
  ),
  Product(
    id: 3,
    name: '抹茶ラテ',
    imagePath: 'products/product_3.png',
    imageUrl: 'https://via.placeholder.com/200x200/8BC34A/FFFFFF?text=Latte',
    description: '抹茶とミルクのラテ',
    category: 'ラテ',
    priceList: [400, 450, 500],
  ),
  Product(
    id: 4,
    name: 'カフェラテ',
    imagePath: 'products/product_4.png',
    imageUrl: 'https://via.placeholder.com/200x200/8BC34A/FFFFFF?text=Latte',
    description: 'まろやかなミルクラテ',
    category: 'ラテ',
    priceList: [350, 400, 450],
  ),
  Product(
    id: 5,
    name: '緑茶',
    imagePath: 'products/product_5.png',
    imageUrl: 'https://via.placeholder.com/200x200/009688/FFFFFF?text=Tea',
    description: '上質な緑茶',
    category: 'ティー',
    priceList: [280, 320],
  ),
  Product(
    id: 6,
    name: '紅茶',
    imagePath: 'products/product_6.png',
    imageUrl: 'https://via.placeholder.com/200x200/009688/FFFFFF?text=Tea',
    description: '香り豊かな紅茶',
    category: 'ティー',
    priceList: [300, 350],
  ),
];
