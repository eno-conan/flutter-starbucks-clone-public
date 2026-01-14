import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/supabase_rpcs.dart';
import '../../constants/supabase_tables.dart';
import '../../core/models/order.dart';
import '../../core/models/order_detail.dart';
import '../../core/services/logger_service.dart';

class OrderService {
  OrderService(this._supabase);
  final SupabaseClient _supabase;

  // シングルトンインスタンス
  static OrderService? _instance;

  // シングルトンインスタンスを取得する
  static OrderService getInstance() {
    if (_instance == null) {
      final supabase = Supabase.instance.client;
      _instance = OrderService(supabase);
    }
    return _instance!;
  }

  String generateRandomString(int length) {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final Random random = Random.secure();
    final String randomStr = List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    return 'order_${randomStr}_001';
  }

  // 新しいオーダーを作成する
  Future<Order> createOrder({
    required String storeNumber,
    required int usage,
    required int orderType,
    required String pickupNumber,
    required int priceWithoutTax,
    required int priceWithTax,
    required String paymentMethod,
  }) async {
    try {
      // ログインユーザーのIDを取得
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // オーダーIDを生成
      final String orderId = generateRandomString(16);

      // 投入するデータを作成
      final orderData = Order(
        orderId: OrderId(orderId),
        userId: UserId(userId),
        storeNumber: StoreNumber(storeNumber),
        usage: usage,
        orderType: orderType,
        pickupNumber: pickupNumber,
        priceWithoutTax: Price(priceWithoutTax),
        priceWithTax: Price(priceWithTax),
        paymentMethod: paymentMethod,
      ).toJson();

      // Supabaseにデータを投入
      final response = await _supabase.from(Tables.orders).insert(orderData).select().single();

      // 作成されたオーダーを返す
      return Order.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        LoggerService.warn('オーダー作成エラー: $e');
      }
      rethrow;
    }
  }

  /// 注文と注文詳細を一括で登録する（トランザクション使用）
  Future<Map<String, dynamic>> createOrderWithDetail({
    required String storeNumber,
    required int usage,
    required int orderType,
    required String pickupNumber,
    required int priceWithoutTax,
    required int priceWithTax,
    required String paymentMethod,
    required List<OrderDetailItem> orderDetails,
  }) async {
    // オーダーIDを生成
    final String orderId = generateRandomString(16);

    try {
      // トランザクションのために直接SQLを実行
      return await _supabase.rpc(
        Rpcs.createOrderWithDetails,
        params: {
          'p_order_id': orderId,
          'p_store_number': storeNumber,
          'p_usage': usage,
          'p_order_type': orderType,
          'p_pickup_number': pickupNumber,
          'p_price_without_tax': priceWithoutTax,
          'p_price_with_tax': priceWithTax,
          'p_payment_method': paymentMethod,
          'p_order_details': orderDetails.map((detail) => detail.toJson()).toList(),
        },
      );
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // オーダーIDでオーダーを検索する
  Future<Order?> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from(Tables.orders)
          .select()
          .eq('order_id', orderId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Order.fromJson(response);
    } catch (e) {
      LoggerService.warn('オーダー検索エラー: $e');
      rethrow;
    }
  }

}
