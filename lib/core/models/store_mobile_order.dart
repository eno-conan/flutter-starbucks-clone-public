import 'package:flutter/material.dart';

class StoreMobileOrder {
  StoreMobileOrder({
    required this.storeNumber,
    required this.storeName,
    this.address,
    this.latitude,
    this.longitude,
    this.openingTime,
    this.closingTime,
    this.distance,
    // this.isFavorite,
  });

  factory StoreMobileOrder.fromJson(Map<String, dynamic> json) {
    // 営業時間の解析
    TimeOfDay? openingTime;
    TimeOfDay? closingTime;

    if (json['opening_time'] != null) {
      final openingTimeStr = json['opening_time'] as String;
      final openingHour = int.parse(openingTimeStr.split(':')[0]);
      final openingMinute = int.parse(openingTimeStr.split(':')[1]);
      openingTime = TimeOfDay(hour: openingHour, minute: openingMinute);
    }

    if (json['closing_time'] != null) {
      final closingTimeStr = json['closing_time'] as String;
      final closingHour = int.parse(closingTimeStr.split(':')[0]);
      final closingMinute = int.parse(closingTimeStr.split(':')[1]);
      closingTime = TimeOfDay(hour: closingHour, minute: closingMinute);
    }

    final distance = (json['distance_km'] as double?) ?? 0;
    // final favorite = (json['is_favorite'] as bool?) ?? false;

    return StoreMobileOrder(
      storeNumber: json['store_number'] as String,
      storeName: json['store_name'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      openingTime: openingTime,
      closingTime: closingTime,
      distance: distance,
      // isFavorite: favorite,
    );
  }
  final String storeNumber;
  final String storeName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final TimeOfDay? openingTime;
  final TimeOfDay? closingTime;
  final double? distance;
  // final bool? isFavorite;

  // 受付可能かどうかを判断
  bool get isAvailableForOrder {
    if (openingTime == null || closingTime == null) {
      return false;
    }

    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    // 現在時刻が営業時間内かをチェック
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final openingMinutes = openingTime!.hour * 60 + openingTime!.minute;
    final closingMinutes = closingTime!.hour * 60 + closingTime!.minute;

    return currentMinutes >= openingMinutes && currentMinutes <= closingMinutes;
  }

  // 営業終了時間を表示用にフォーマット (21:30 形式)
  String? get formattedClosingTime {
    if (closingTime == null) {
      return null;
    }

    final hour = closingTime!.hour.toString().padLeft(2, '0');
    final minute = closingTime!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String? get formattedDistanceKm {
    if (distance == null) {
      return null;
    }

    final String formattedDistance = ((distance! * 100).truncateToDouble() / 100).toStringAsFixed(
      1,
    );
    return '$formattedDistance km';
  }
}
