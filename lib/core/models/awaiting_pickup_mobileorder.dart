import 'package:intl/intl.dart';

///受取待ちのモバイルオーダー情報
class AwaitingPickupOrder {
  AwaitingPickupOrder({
    required this.pickupNumber,
    required this.createdAt,
    required this.storeName,
    this.pickupTime,
  });

  // パラメータなしのデフォルトコンストラクタ
  AwaitingPickupOrder.empty()
    : pickupNumber = '',
      createdAt = DateTime.now(),
      storeName = '',
      pickupTime = null;

  factory AwaitingPickupOrder.fromJson(Map<String, dynamic> json) {
    return AwaitingPickupOrder(
      pickupNumber: json['pickup_number'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      storeName: json['stores']['store_name'] as String,
      pickupTime: json['pickup_time'] != null
          ? DateTime.parse(json['pickup_time'] as String)
          : null,
    );
  }

  final String pickupNumber;
  final DateTime createdAt;
  final String storeName;
  final DateTime? pickupTime;

  // 注文完了日時の表示フォーマット
  String get formattedCreatedDate {
    return DateFormat('yyyy/MM/dd HH:mm').format(createdAt.toLocal());
  }
}
