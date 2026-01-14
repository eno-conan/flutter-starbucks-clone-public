import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/supabase_rpcs.dart';
import '../../constants/supabase_tables.dart';
import '../../core/models/mobile_order_history.dart';
import '../../core/models/order.dart';

///注文テーブルのDB操作
class OrderRepository {
  OrderRepository(this._supabase);
  final SupabaseClient _supabase;

  /// ユーザーの注文履歴を取得
  Future<List<MobileOrderHistory>> getUserOrderHistories(String userId) async {
    final response = await _supabase.rpc(
      Rpcs.getUsersOrdersWithFullDetails,
      params: {'p_user_id': userId},
    );
    final List<dynamic> data = response as List<dynamic>;
    final List<MobileOrderHistory> histories = data
        .map((json) => MobileOrderHistory.fromJson(json as Map<String, dynamic>))
        .toList();
    return histories;
  }

  /// 特定の注文IDの詳細を取得
  Future<Order?> getOrderById(String orderId) async {
    final response = await _supabase
        .from(Tables.orders)
        .select()
        .eq('order_id', orderId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Order.fromJson(response);
  }

  // /// 注文詳細を取得
  // Future<List<OrderDetail>> getOrderDetails(String orderId) async {
  //   final response = await _supabase
  //       .from(Tables.ordersDetail)
  //       .select()
  //       .eq('order_id', orderId);

  //   final List<dynamic> data = response as List<dynamic>;
  //   return data
  //       .map((json) => OrderDetail.fromJson(json as Map<String, dynamic>))
  //       .toList();
  // }

  // /// 新規注文を作成
  // Future<String> createOrder(Order order, List<OrderDetail> orderDetails) async {
  //   final orderResponse = await _supabase.rpc(
  //     Rpcs.createOrderWithDetails,
  //     params: {
  //       'p_user_id': order.userId,
  //       'p_store_number': order.storeNumber,
  //       'p_usage': order.usage,
  //       'p_total_amount': order.totalAmount,
  //       'p_order_details': orderDetails.map((detail) => detail.toJson()).toList(),
  //     },
  //   );

  //   // 注文IDを返す（実際のレスポンス形式に応じて調整）
  //   return orderResponse.toString();
  // }

  /// 注文ステータスを更新（店舗側で使用）
  Future<void> updateOrderStatus(String orderId, int providedStatus) async {
    await _supabase
        .from(Tables.orders)
        .update({'provided_status': providedStatus})
        .eq('order_id', orderId);
  }

  /// 待機中の注文を取得（ピックアップ待ちの注文）
  Future<List<Order>> getAwaitingPickupOrders(String userId) async {
    final response = await _supabase
        .from(Tables.orders)
        .select()
        .eq('user_id', userId)
        .inFilter('provided_status', [0, 1]) // 0: 未受付, 1: 調理中
        .order('order_date', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => Order.fromJson(json as Map<String, dynamic>)).toList();
  }

  // /// 店舗の注文一覧を取得（店舗側で使用）
  // Future<List<Order>> getStoreOrders(String storeNumber) async {
  //   final response = await _supabase.rpc(
  //     Rpcs.getStoreOrderList,
  //     params: {'p_store_number': storeNumber},
  //   );

  //   final List<dynamic> data = response as List<dynamic>;
  //   return data
  //       .map((json) => Order.fromJson(json as Map<String, dynamic>))
  //       .toList();
  // }
}
