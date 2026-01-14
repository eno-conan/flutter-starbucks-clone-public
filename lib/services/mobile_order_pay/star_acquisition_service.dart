import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/supabase_rpcs.dart';
import '../../constants/supabase_tables.dart';

///スター獲得時のデータを扱うサービス
class StarAcquisitionService {
  StarAcquisitionService(this._supabaseClient);
  final SupabaseClient _supabaseClient;

  // シングルトンインスタンス
  static StarAcquisitionService? _instance;

  // シングルトンインスタンスを取得する
  static StarAcquisitionService getInstance() {
    if (_instance == null) {
      final supabase = Supabase.instance.client;
      _instance = StarAcquisitionService(supabase);
    }
    return _instance!;
  }

  /// 星獲得データをテーブルに挿入する
  Future<void> insertStarAcquisition({
    required String orderId,
    required int category,
    required int priceWithTax,
  }) async {
    // ログインユーザーのIDを取得
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ユーザーがログインしていません');
    }

    // 60円で割り算
    final double acquiredPoints = (priceWithTax / 60 * 100).truncateToDouble() / 100;

    try {
      // データを挿入(関数呼び出し)
      await _supabaseClient.rpc<void>(
        Rpcs.handleStarAcquisition,
        params: {
          'p_user_id': userId,
          'p_order_id': orderId,
          'p_category': category,
          'p_acquired_points': acquiredPoints,
        },
      );
    } catch (e) {
      throw Exception('Failed to insert star acquisition data: $e');
    }
  }

  /// 特定ユーザーの星獲得履歴を取得する（オプション機能）
  Future<List<Map<String, dynamic>>> getStarAcquisitionsByUserId(String userId) async {
    try {
      final response = await _supabaseClient
          .from(Tables.starAcquisitions)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Failed to get star acquisitions: $e');
    }
  }
}
