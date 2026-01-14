import 'package:flutter/material.dart' show TimeOfDay;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/order_validation_result.dart';
import '../../core/services/logger_service.dart';
import '../../data/repository/store.dart';

/// 注文検証専用サービス
///
/// BuildContextに依存せず、検証結果のみを返します。
/// これにより、サービス層の単体テストが容易になり、
/// UI層との責務分離が明確になります。
class OrderValidationService {
  OrderValidationService._();
  static OrderValidationService? _instance;

  /// シングルトンインスタンスを取得
  static OrderValidationService getInstance() {
    _instance ??= OrderValidationService._();
    return _instance!;
  }

  /// 店舗の営業状況を検証
  ///
  /// 店舗の閉店時刻を取得し、注文可能かどうかを判定します。
  /// 閉店15分前以降の場合は、StoreClosingSoonを返します。
  ///
  /// パラメータ:
  /// - [storeNumber]: 店舗番号
  ///
  /// 戻り値:
  /// - [ValidationSuccess]: 注文可能
  /// - [StoreClosingSoon]: 閉店15分前以降
  /// - [ValidationError]: エラー発生
  Future<OrderValidationResult> validateStoreStatus(String storeNumber) async {
    try {
      LoggerService.info('店舗営業状況検証開始: storeNumber=$storeNumber');

      final supabase = Supabase.instance.client;
      final storeRepository = StoreRepository(supabase);
      final closingTime = await storeRepository.getStoreClosingTime(storeNumber);

      if (closingTime == null) {
        LoggerService.warn('店舗の閉店時刻取得に失敗: storeNumber=$storeNumber');
        return const ValidationError(
          errorType: ValidationErrorType.storeNotFound,
          message: '店舗情報の取得に失敗しました',
        );
      }

      if (storeRepository.isWithin15MinutesBeforeClosing(closingTime)) {
        final minutesUntilClosing = _calculateMinutesUntilClosing(closingTime);
        LoggerService.info('閉店時間間近を検出: 残り$minutesUntilClosing分');

        return StoreClosingSoon(
          closingTime: _formatTimeOfDay(closingTime),
          minutesUntilClosing: minutesUntilClosing,
        );
      }

      LoggerService.info('店舗営業状況検証完了: 注文可能');
      return const ValidationSuccess();
    } catch (e) {
      LoggerService.warn('店舗営業状況検証エラー', e);
      return ValidationError(
        errorType: ValidationErrorType.networkError,
        message: '店舗情報の取得中にエラーが発生しました',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// 閉店までの残り分数を計算
  int _calculateMinutesUntilClosing(TimeOfDay closingTime) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final closingMinutes = closingTime.hour * 60 + closingTime.minute;
    return closingMinutes - currentMinutes;
  }

  /// TimeOfDayを文字列にフォーマット（"HH:mm"形式）
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
