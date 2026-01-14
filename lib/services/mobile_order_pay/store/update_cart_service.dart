import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../constants/supabase_tables.dart';
import '../../../core/models/cart.dart';
import '../../../core/models/store_mobile_order.dart';

class CartService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> addToCartAndNavigate({required StoreMobileOrder store}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ユーザーが認証されていません');
    }

    final cart = Cart(userId: userId, storeNumber: store.storeNumber, usage: 1);
    await _supabase.from(Tables.carts).upsert(cart.toJson()).select().maybeSingle();
  }
}
