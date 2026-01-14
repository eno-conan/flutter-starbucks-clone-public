// 購入履歴のモデルクラス
import 'package:intl/intl.dart';

class PurchaseHistory {
  PurchaseHistory({
    required this.id,
    required this.productName,
    required this.price,
    required this.starPoints,
    required this.storeName,
    required this.cardNumber,
    required this.purchaseDateTime,
  });

  factory PurchaseHistory.fromJson(Map<String, dynamic> json) {
    return PurchaseHistory(
      id: json['id'] as String,
      productName: json['product_name'] as String,
      price: json['price'] as int,
      starPoints: (json['star_points'] as num).toDouble(),
      storeName: json['store_name'] as String,
      cardNumber: json['card_number'] as String,
      purchaseDateTime: DateTime.parse(json['purchase_datetime'] as String),
    );
  }
  final String id;
  final String productName;
  final int price;
  final double starPoints;
  final String storeName;
  final String cardNumber;
  final DateTime purchaseDateTime;

  // 日付部分だけを取得する getter
  String get formattedPurchaseDate {
    return DateFormat('yyyy/MM/dd').format(purchaseDateTime.toLocal());
  }
}

// 月ごとに集計された購入履歴のモデルクラス
class MonthlyPurchaseHistory {
  MonthlyPurchaseHistory({required this.month, required this.purchases});
  final DateTime month;
  final List<PurchaseHistory> purchases;
}
