/// 店舗の注文情報（1つの注文IDに紐づく情報）
class StoreOrder {
  StoreOrder({
    required this.orderId,
    required this.storeNumber,
    required this.storeName,
    required this.providedStatus,
    required this.usage,
    required this.pickupNumber,
    required this.items,
    required this.isCompleted,
  });
  final String orderId;
  final String storeNumber;
  final String storeName;
  final String providedStatus;
  final int usage; // 1:店内 2:テイクアウト
  final String pickupNumber;
  final List<StoreOrderItem> items;
  bool isCompleted;

  /// 注文の合計商品数を計算
  int get totalItemCount {
    return items.fold(0, (sum, item) => sum + item.count);
  }

  /// JSONから変換するファクトリメソッド（リスト全体を処理）
  static List<StoreOrder> fromJsonList(List<dynamic> jsonList) {
    final ordersMap = <String, StoreOrder>{};

    for (final item in jsonList.cast<Map<String, dynamic>>()) {
      try {
        final orderId = item['order_id'].toString();
        final orderItem = StoreOrderItem.fromJson(item);

        if (ordersMap.containsKey(orderId)) {
          ordersMap[orderId]!.items.add(orderItem);
        } else {
          ordersMap[orderId] = StoreOrder(
            orderId: orderId,
            storeNumber: item['store_number'].toString(),
            storeName: item['store_name'].toString(),
            providedStatus: item['provided_status'].toString(),
            usage: _parseInt(item['usage']),
            pickupNumber: item['pickup_number'].toString(),
            items: [orderItem],
            isCompleted: false,
          );
        }
      } catch (e) {
        // debugPrint('Error parsing order item: $e');
        continue;
      }
    }

    return ordersMap.values.toList();
  }

  /// 安全なint型への変換
  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  @override
  String toString() {
    return '''
    StoreOrder {
      orderId: $orderId,
      storeNumber: $storeNumber,
      storeName: $storeName,
      usage: ${usage == 1 ? '店内' : 'テイクアウト'},
      pickupNumber: $pickupNumber,
      itemCount: ${items.length},
      totalQuantity: $totalItemCount,
      items: ${items.map((item) => item.toString()).join('\n    ')}
    }''';
  }
}

/// 店舗注文に含まれる個々の商品
class StoreOrderItem {
  StoreOrderItem({
    required this.detailId,
    required this.productName,
    required this.temperatureType,
    required this.sizeName,
    required this.count,
  });

  factory StoreOrderItem.fromJson(Map<String, dynamic> json) {
    return StoreOrderItem(
      detailId: json['detail_id'].toString(),
      productName: json['product_name'].toString(),
      temperatureType: json['temperature_type'].toString(),
      sizeName: json['size_name'].toString(),
      count: StoreOrder._parseInt(json['count']),
    );
  }
  final String detailId;
  final String productName;
  final String temperatureType; // HOT/ICE
  final String sizeName; // Tall/Grande etc
  final int count;

  Map<String, dynamic> toJson() {
    return {
      'detail_id': detailId,
      'product_name': productName,
      'temperature_type': temperatureType,
      'size_name': sizeName,
      'count': count,
    };
  }

  @override
  String toString() {
    return '''
    StoreOrderItem {
      detailId: $detailId,
      productName: $productName,
      temperatureType: $temperatureType,
      sizeName: $sizeName,
      count: $count
    }''';
  }
}
