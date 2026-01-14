import 'package:intl/intl.dart';

final _formatter = NumberFormat('#,###');

// Extension Typeの定義
extension type OrderId(String value) {
  bool get isValid => value.isNotEmpty;
  String get displayId => 'Order-${value.substring(0, 8)}';
}

extension type UserId(String value) {
  bool get isValid => value.isNotEmpty && value.length >= 3;
}

extension type StoreNumber(String value) {
  bool get isValid => RegExp(r'^\d+$').hasMatch(value);
}

extension type Price(int value) {
  String get formatted => '¥${_formatter.format(value)}';
  Price operator +(Price other) => Price(value + other.value);
}

// リファクタリングされたOrderクラス
class Order {
  Order({
    this.id,
    required this.orderId,
    required this.userId,
    required this.storeNumber,
    required this.usage,
    required this.orderType,
    required this.pickupNumber,
    required this.priceWithoutTax,
    required this.priceWithTax,
    required this.paymentMethod,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String?,
      orderId: OrderId(json['order_id'] as String),
      userId: UserId(json['user_id'] as String),
      storeNumber: StoreNumber(json['store_number'] as String),
      usage: json['usage'] as int,
      orderType: json['order_type'] as int,
      pickupNumber: json['pickup_number'] as String,
      priceWithoutTax: Price(json['price_without_tax'] as int),
      priceWithTax: Price(json['price_with_tax'] as int),
      paymentMethod: json['payment_method'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String? id;
  final OrderId orderId;
  final UserId userId;
  final StoreNumber storeNumber;
  final int usage;
  final int orderType;
  final String pickupNumber;
  final Price priceWithoutTax;
  final Price priceWithTax;
  final String paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'order_id': orderId.value,
      'user_id': userId.value,
      'store_number': storeNumber.value,
      'usage': usage,
      'order_type': orderType,
      'pickup_number': pickupNumber,
      'price_without_tax': priceWithoutTax.value,
      'price_with_tax': priceWithTax.value,
      'payment_method': paymentMethod,
    };

    if (id != null) {
      data['id'] = id;
    }

    return data;
  }
}
