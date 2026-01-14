import 'package:intl/intl.dart';
import '../../shared/helpers/timezone_util.dart';

final _formatter = NumberFormat('#,###');

///モバイルオーダーの履歴表示タブで用いるモデル
class MobileOrderHistory {
  MobileOrderHistory({
    required this.orderId,
    required this.usage,
    required this.createdAt,
    required this.storeNumber,
    required this.storeName,
    required this.storeAddress,
    required this.pickupNumber,
    required this.priceWithoutTax,
    required this.priceWithTax,
    required this.paymentMethod,
    required this.items,
  });

  factory MobileOrderHistory.fromJson(Map<String, dynamic> json) {
    return MobileOrderHistory(
      orderId: json['order_id'] as String,
      usage: json['usage'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      storeNumber: json['store_number'] as String,
      storeName: json['store_name'] as String,
      storeAddress: json['store_address'] as String,
      pickupNumber: json['pickup_number'] as String,
      priceWithoutTax: json['price_without_tax'] as int,
      priceWithTax: json['price_with_tax'] as int,
      paymentMethod: json['payment_method'] as String,
      items: (json['items'] as List)
          .map((item) => MobileOrderHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
  final String orderId;
  final int usage;
  final DateTime createdAt;
  final String storeNumber;
  final String storeName;
  final String storeAddress;
  final String pickupNumber;
  final int priceWithoutTax;
  final int priceWithTax;
  final String paymentMethod;
  final List<MobileOrderHistoryItem> items;

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'usage': usage,
      'created_at': createdAt.toIso8601String(),
      'store_number': storeNumber,
      'store_name': storeName,
      'store_address': storeAddress,
      'price_without_tax': priceWithoutTax,
      'price_with_tax': priceWithTax,
      'payment_method': paymentMethod,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // 税抜
  String get formattedPriceWithoutTax => _formatter.format(priceWithoutTax);
  // 税込
  String get formattedPriceWithTax => _formatter.format(priceWithTax);
  // 税額
  String get formattedTax => _formatter.format(priceWithTax - priceWithoutTax);

  String get usageLabel => usage == 1 ? '店内' : 'テイクアウト';

  String get formattedOrderDate => TimezoneUtil.formatLocalTime(createdAt);

  @override
  String toString() {
    return '''
MobileOrderHistory(
  orderId: $orderId,
  usage: $usageLabel,
  createdAt: $formattedOrderDate,
  storeNumber: $storeNumber,
  storeName: $storeName,
  storeAddress: $storeAddress,
  pickupNumber: $pickupNumber,
  priceWithoutTax: ¥$formattedPriceWithoutTax,
  priceWithTax: ¥$formattedPriceWithTax,
  paymentMethod: $paymentMethod,
  items: $items
  )
    ''';
  }
}

class MobileOrderHistoryItem {
  MobileOrderHistoryItem({
    required this.productId,
    required this.productName,
    required this.sizeId,
    required this.sizeName,
    required this.temperatureTypeId,
    required this.temperatureTypeName,
    required this.count,
    required this.subtotalWithoutTax,
  });

  factory MobileOrderHistoryItem.fromJson(Map<String, dynamic> json) {
    return MobileOrderHistoryItem(
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      sizeId: json['size_id'] as int,
      sizeName: json['size_name'] as String,
      temperatureTypeId: json['temperature_type_id'] as int,
      temperatureTypeName: json['temperature_type_name'] as String,
      count: json['count'] as int,
      subtotalWithoutTax: json['subtotal_without_tax'] as int,
    );
  }
  final int productId;
  final String productName;
  final int sizeId;
  final String sizeName;
  final int temperatureTypeId;
  final String temperatureTypeName;
  final int count;
  final int subtotalWithoutTax;

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'size_id': sizeId,
      'size_name': sizeName,
      'temperature_type_id': temperatureTypeId,
      'temperature_type_name': temperatureTypeName,
      'count': count,
      'subtotal_without_tax': subtotalWithoutTax,
    };
  }

  @override
  String toString() {
    return '''
MobileOrderHistoryItem(
  productId: $productId,
  productName: $productName,
  sizeId: $sizeId,
  sizeName: $sizeName,
  count: $count,
  subtotalWithoutTax: ¥${_formatter.format(subtotalWithoutTax)}
)
''';
  }
}
