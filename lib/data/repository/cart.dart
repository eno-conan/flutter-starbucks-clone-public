import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/supabase_rpcs.dart';
import '../../constants/supabase_tables.dart';
import '../../core/models/cart.dart';
import '../../core/models/cart_detail.dart';

///cartテーブルのDB操作
class CartRepository {
  CartRepository(this._supabase);
  final SupabaseClient _supabase;

  // カートの取得
  Future<Cart?> getUserCart(String userId) async {
    final response = await _supabase
        .from(Tables.carts)
        .select()
        .eq('user_id', userId)
        .maybeSingle(); // single() の代わりに maybeSingle() を使用

    if (response == null) {
      return null; // レコードが存在しない場合
    }

    return Cart.fromJson(response);
  }

  /// ドライブスルーステータスの取得
  Future<bool> isStoreDriveThruAvailable(String userId) async {
    final response = await _supabase.rpc<List<Map<String, dynamic>>>(
      Rpcs.getSelectStoreDriveThruStatus,
      params: {'p_user_id': userId},
    );
    if (response.isNotEmpty) {
      final data = response.first;
      return data['is_drive_thru_available'] == 1;
    }
    return false;
  }

  // カートの更新（upsert操作）
  Future<void> upsertCart(Cart cart) async {
    await _supabase.from(Tables.carts).upsert(cart.toJson()).select().single();
  }

  /// カート全体を空にする（概要テーブルと詳細テーブル両方を削除）
  Future<void> clearUserCart(String userId) async {
    await Future.wait([
      _supabase.from(Tables.cartsDetail).delete().eq('user_id', userId),
      _supabase.from(Tables.carts).delete().eq('user_id', userId),
    ]);
  }

  /// カート詳細リストを挿入（複数の商品を一度に挿入）
  Future<void> insertCartDetails(List<CartDetail> cartDetails) async {
    final cartDetailMaps = cartDetails.map((detail) => detail.toJson()).toList();
    await _supabase.from(Tables.cartsDetail).insert(cartDetailMaps);
  }

  /// ユーザーIDに基づくカート詳細リストの存在確認
  Future<bool> hasCartDetails(String userId) async {
    final response = await _supabase
        .from(Tables.cartsDetail)
        .select('user_id')
        .eq('user_id', userId)
        .limit(1);
    return response.isNotEmpty;
  }
}
