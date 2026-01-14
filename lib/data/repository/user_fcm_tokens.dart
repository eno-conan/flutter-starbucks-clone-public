import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/supabase_tables.dart';
import '../../core/models/user_fcm_token.dart';

class UserFcmTokenRepository {
  UserFcmTokenRepository(this._supabase);
  final SupabaseClient _supabase;

  /// ユーザーの通知設定情報を取得する
  Future<UserFcmToken> getNotificationStatus(String userId) async {
    final response = await _supabase
        .from(Tables.userFcmTokens)
        .select('is_notify')
        .eq('user_id', userId)
        .single();
    return UserFcmToken.fromJson(response);
  }

  /// 通知設定（is_notify）を更新する
  Future<void> updateNotificationStatus(String userId, int status) async {
    await _supabase.from(Tables.userFcmTokens).update({'is_notify': status}).eq('user_id', userId);
  }
}
