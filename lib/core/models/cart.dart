// ignore_for_file: avoid_dynamic_calls

import 'package:intl/intl.dart';

class Cart {
  Cart({
    required this.userId,
    required this.storeNumber,
    this.storeName,
    this.address,
    this.usage,
    this.paymentMethod,
    this.createdAt,
    this.updatedAt,
  });

  // JSONからCartを作成
  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      userId: json['user_id'] as String,
      storeNumber: json['store_number'] as String,
      storeName: json['store_name'] as String?,
      address: json['address'] as String?,
      usage: json['usage'] as int?,
      paymentMethod: json['payment_method'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  final String userId;
  final String storeNumber;
  final String? storeName;
  final String? address;
  final int? usage; //1: eat-in, 2: takeout ,3: drive through
  final String? paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // CartをJSONに変換
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'store_number': storeNumber,
      'usage': usage,
      'payment_method': paymentMethod,
    };

    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      data['updated_at'] = updatedAt!.toIso8601String();
    }

    return data;
  }

  // モデルのコピーを作成して特定のフィールドを更新
  Cart copyWith({
    String? userId,
    String? storeNumber,
    String? storeName,
    String? address,
    int? usage,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      userId: userId ?? this.userId,
      storeNumber: storeNumber ?? this.storeNumber,
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      usage: usage ?? this.usage,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper関数：usageに基づいて税率を返す
  double getTaxRate() {
    switch (usage) {
      case 0: // eat-in
        return 0.08;
      case 1: // takeout
        return 0.10;
      default:
        return 0.08; // デフォルトはeat-in税率
    }
  }

  // Helper関数：画面表示用の整数税率を返す（パーセント表示用）
  int getTaxRateAsPercent() {
    switch (usage) {
      case 0: // eat-in
        return 8;
      case 1: // takeout
        return 10;
      default:
        return 8; // デフォルトはeat-in税率
    }
  }

  // Helper関数：数値をカンマ編集した文字列として返す
  static String formatWithComma(int amount) {
    final formatter = NumberFormat('#,###');
    return formatter.format(amount);
  }
}
