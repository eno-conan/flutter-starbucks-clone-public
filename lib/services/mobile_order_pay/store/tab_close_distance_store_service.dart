import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../constants/supabase_rpcs.dart';
import '../../../core/models/store_mobile_order.dart';

class CloseDistanceStoreService {
  // 実際はHTTP通信でデータを取得する部分
  Future<List<StoreMobileOrder>> getCloseDistanceStoreStores(
    double latitude,
    double longitude,
  ) async {
    final SupabaseClient supabase = Supabase.instance.client;
    final response = await supabase.rpc(
      Rpcs.getNearbyStores,
      params: {'lat': latitude, 'lng': longitude, 'radius_km': 30.0},
    );
    final List<dynamic> data = response as List<dynamic>;
    final List<StoreMobileOrder> stores = data
        .map((json) => StoreMobileOrder.fromJson(json as Map<String, dynamic>))
        .toList();
    return stores;
  }
}
