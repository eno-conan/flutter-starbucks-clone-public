import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/cart.dart';
import '../core/models/cart_detail.dart';
import '../core/models/mobile_order_completion.dart';
import '../core/models/order_validation_result.dart';
import '../core/services/logger_service.dart';
import '../services/mobile_order_pay/order_settlement_service.dart';
import '../services/mobile_order_pay/order_validation_service.dart';

/// 注文決済処理の状態
///
/// Sealed classを使用することで、すべての状態を型安全に扱えます。
sealed class OrderSettlementState {
  const OrderSettlementState();
}

/// 初期状態
class OrderSettlementInitial extends OrderSettlementState {
  const OrderSettlementInitial();
}

/// 検証中
class OrderSettlementValidating extends OrderSettlementState {
  const OrderSettlementValidating();
}

/// 検証失敗
class OrderSettlementValidationFailed extends OrderSettlementState {
  const OrderSettlementValidationFailed(this.result);

  /// 検証結果
  final OrderValidationResult result;
}

/// 決済処理中
class OrderSettlementProcessing extends OrderSettlementState {
  const OrderSettlementProcessing();
}

/// 決済成功
class OrderSettlementSuccess extends OrderSettlementState {
  const OrderSettlementSuccess(this.completion);

  /// 注文完了情報
  final MobileOrderCompletion completion;
}

/// 決済エラー
class OrderSettlementError extends OrderSettlementState {
  const OrderSettlementError(this.message, this.exception);

  /// エラーメッセージ
  final String message;

  /// 発生した例外
  final Exception? exception;
}

/// 注文決済処理を管理するNotifier
///
/// 店舗営業状況の検証から決済処理までを一貫して管理します。
class OrderSettlementNotifier extends Notifier<OrderSettlementState> {
  @override
  OrderSettlementState build() {
    return const OrderSettlementInitial();
  }

  /// 店舗営業状況を検証
  ///
  /// パラメータ:
  /// - [storeNumber]: 店舗番号
  ///
  /// 戻り値: 検証結果
  Future<OrderValidationResult> validateStoreStatus(String storeNumber) async {
    state = const OrderSettlementValidating();
    LoggerService.info('注文前検証開始');

    final validationService = OrderValidationService.getInstance();
    final result = await validationService.validateStoreStatus(storeNumber);

    if (result is! ValidationSuccess) {
      state = OrderSettlementValidationFailed(result);
      LoggerService.warn('注文前検証失敗');
    }

    return result;
  }

  /// 決済処理を実行
  ///
  /// パラメータ:
  /// - [cart]: カート情報
  /// - [cartDetails]: カート詳細情報
  /// - [totalAmountExcludingTax]: 税抜き合計金額
  /// - [totalAmountIncludingTax]: 税込み合計金額
  /// - [nickname]: ニックネーム（オプション）
  Future<void> processSettlement({
    required Cart cart,
    required List<CartDetail> cartDetails,
    required int totalAmountExcludingTax,
    required int totalAmountIncludingTax,
    String? nickname,
  }) async {
    try {
      state = const OrderSettlementProcessing();
      LoggerService.info('決済処理開始');

      final settlementService = OrderSettlementService.getInstance();
      final completion = await settlementService.processSettlement(
        cart: cart,
        cartDetails: cartDetails,
        totalAmountExcludingTax: totalAmountExcludingTax,
        totalAmountIncludingTax: totalAmountIncludingTax,
        nickname: nickname,
      );

      state = OrderSettlementSuccess(completion);
      LoggerService.info('決済処理完了');
    } catch (e) {
      LoggerService.warn('決済処理エラー', e);
      state = OrderSettlementError(
        '決済処理中にエラーが発生しました',
        e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  /// 状態をリセット
  ///
  /// 次の注文処理のために状態を初期化します。
  void reset() {
    state = const OrderSettlementInitial();
  }
}

/// 注文決済Providerの定義
final orderSettlementProvider =
    NotifierProvider<OrderSettlementNotifier, OrderSettlementState>(
  OrderSettlementNotifier.new,
);
