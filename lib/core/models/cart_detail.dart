import 'dart:convert';

import 'package:intl/intl.dart';

class CartDetail {
  CartDetail({
    this.userId,
    required this.itemIndex,
    required this.productId,
    required this.temperatureTypeId,
    required this.sizeId,
    required this.count,
    required this.subtotalWithoutTax,
    this.productName,
    this.typeName,
    this.sizeName,
  });

  // JSONからオブジェクトを生成するファクトリメソッド
  factory CartDetail.fromJson(Map<String, dynamic> json) {
    return CartDetail(
      itemIndex: json['item_index'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String?,
      temperatureTypeId: json['temperature_type_id'] as int,
      typeName: json['type_name'] as String?,
      sizeId: json['size_id'] as int,
      sizeName: json['size_name'] as String?,
      count: json['count'] as int,
      subtotalWithoutTax: json['subtotal_without_tax'] as int,
    );
  }

  // JSON文字列からオブジェクトを生成するファクトリメソッド
  factory CartDetail.fromJsonString(String jsonString) {
    return CartDetail.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  final String? userId;
  final int itemIndex;
  final int productId;
  final int temperatureTypeId;
  final int sizeId;
  final int count;
  final int subtotalWithoutTax;
  final String? productName;
  final String? typeName;
  final String? sizeName;

  // JSON形式に変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'item_index': itemIndex,
      'product_id': productId,
      'temperature_type_id': temperatureTypeId,
      'size_id': sizeId,
      'count': count,
      'subtotal_without_tax': subtotalWithoutTax,
      if (productName != null) 'product_name': productName,
      if (typeName != null) 'type_name': typeName,
      if (sizeName != null) 'size_name': sizeName,
    };
  }

  // JSON文字列に変換
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Helper関数：CartDetailリストのsubtotalWithoutTaxを合計
  static int calculateTotalSubtotal(List<CartDetail> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + item.subtotalWithoutTax);
  }

  // Helper関数：数値をカンマ編集した文字列として返す
  static String formatWithComma(int amount) {
    final formatter = NumberFormat('#,###');
    return formatter.format(amount);
  }

  // Helper関数：空リストや空の場合の安全な合計計算（カンマ編集版）
  static String calculateTotalSubtotalSafe(List<CartDetail>? cartItems) {
    if (cartItems == null || cartItems.isEmpty) {
      return formatWithComma(0);
    }
    final total = calculateTotalSubtotal(cartItems);
    return formatWithComma(total);
  }

  // Helper関数：数値版も残しておく（必要に応じて）
  static int calculateTotalSubtotalSafeAsInt(List<CartDetail>? cartItems) {
    if (cartItems == null || cartItems.isEmpty) {
      return 0;
    }
    return calculateTotalSubtotal(cartItems);
  }
}
