import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/cart.dart';
import '../../core/models/cart_detail.dart';
import '../../core/models/mobile_order_completion.dart';
import '../../core/models/order_detail.dart';
import '../../data/repository/cart.dart';
import '../../screens/starbucks_user_side/mobile_order_pay/tab_order/constants.dart';
import '../auth_service.dart';
import 'order_creation_service.dart';
import 'star_acquisition_service.dart';

/// 注文決済処理を担当するサービスクラス
class OrderSettlementService {
  OrderSettlementService._();
  static OrderSettlementService? _instance;

  /// シングルトンインスタンスを取得
  static OrderSettlementService getInstance() {
    _instance ??= OrderSettlementService._();
    return _instance!;
  }

  /// 受付番号を生成する
  Future<String> createReceivedNumber({String? nickname}) async {
    // ニックネームが登録されている場合はそれを使用
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }

    // ニックネームがない場合は従来通りランダム生成
    final random = Random.secure();
    final String randomCountry = countries[random.nextInt(countries.length)];
    final String randomNumber = numbers[random.nextInt(numbers.length)];
    return '$randomCountry*$randomNumber';
  }

  /// 注文をデータベースに保存する
  Future<void> saveOrderToDatabase({
    required Cart cart,
    required List<CartDetail> cartDetails,
    required String receivedNumber,
    required int totalAmountExcludingTax,
    required int totalAmountIncludingTax,
  }) async {
    final orderService = OrderService.getInstance();

    if (cart.storeNumber.isEmpty) {
      throw Exception('店舗情報が登録されていません');
    }

    // 注文詳細情報を作成
    final List<OrderDetailItem> orderDetails = [];
    for (final product in cartDetails) {
      final OrderDetailItem detail = OrderDetailItem(
        productId: product.productId,
        temperatureTypeId: product.temperatureTypeId,
        sizeId: product.sizeId,
        count: product.count,
        subtotalWithoutTax: product.subtotalWithoutTax,
      );
      orderDetails.add(detail);
    }

    // 注文を作成
    final Map<String, dynamic> insertOrderResult = await orderService.createOrderWithDetail(
      storeNumber: cart.storeNumber,
      usage: cart.usage ?? 0,
      orderType: 2, // モバイルオーダー
      pickupNumber: receivedNumber,
      priceWithoutTax: totalAmountExcludingTax,
      priceWithTax: totalAmountIncludingTax,
      paymentMethod: 'クレジットカード',
      orderDetails: orderDetails,
    );

    final order = insertOrderResult['order'];
    // ignore: avoid_dynamic_calls
    final orderId = order['order_id'] as String;

    if (kDebugMode) {
      // debugPrint('注文結果： ${insertOrderResult["success"]}');
      // debugPrint('注文： $insertOrderResult');
    }

    // スターリワード情報の登録
    final starService = StarAcquisitionService.getInstance();
    starService.insertStarAcquisition(
      orderId: orderId,
      category: 2,
      priceWithTax: totalAmountIncludingTax,
    );
  }

  /// カート情報をクリアする
  Future<void> clearCart() async {
    final SupabaseClient supabase = Supabase.instance.client;
    final authService = AuthService();
    final CartRepository cartRepository = CartRepository(supabase);

    cartRepository.clearUserCart(authService.getUserId());
  }

  /// 完了画面用のデータを作成する
  MobileOrderCompletion createCompletionData({required Cart cart, required String pickupNumber}) {
    return MobileOrderCompletion(
      storeNumber: cart.storeNumber,
      storeName: cart.storeName ?? '',
      pickupNumber: pickupNumber,
      address: cart.address ?? '',
    );
  }

  /// 決済処理を実行する
  Future<MobileOrderCompletion> processSettlement({
    required Cart cart,
    required List<CartDetail> cartDetails,
    required int totalAmountExcludingTax,
    required int totalAmountIncludingTax,
    String? nickname,
  }) async {
    try {
      // 受付番号を生成（ニックネームがある場合はそれを使用）
      final String receivedNumber = await createReceivedNumber(nickname: nickname);

      // 注文をデータベースに保存
      await saveOrderToDatabase(
        cart: cart,
        cartDetails: cartDetails,
        receivedNumber: receivedNumber,
        totalAmountExcludingTax: totalAmountExcludingTax,
        totalAmountIncludingTax: totalAmountIncludingTax,
      );

      // カート情報をクリア
      await clearCart();

      // 完了画面用のデータを作成
      return createCompletionData(cart: cart, pickupNumber: receivedNumber);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('決済処理中にエラーが発生しました: $e');
      }
      rethrow;
    }
  }
}
