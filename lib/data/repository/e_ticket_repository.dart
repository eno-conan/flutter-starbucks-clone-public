import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/supabase_rpcs.dart';
import '../../core/models/user_ticket.dart';
import '../../core/services/logger_service.dart';

/// eチケットテーブルのDB操作
///
/// Supabase RPC関数を使用してeチケットデータを取得します。
class ETicketRepository {
  ETicketRepository(this._supabase);
  final SupabaseClient _supabase;

  /// ユーザーの利用可能なeチケットを取得
  ///
  /// 未使用で有効期限内のチケットのみを返します。
  /// RPC関数: get_user_available_tickets
  ///
  /// [userId] ユーザーID (auth.users.id)
  /// Returns 利用可能なチケットのリスト（有効期限の早い順）
  Future<List<AvailableTicket>> getUserAvailableTickets(String userId) async {
    LoggerService.info('利用可能eチケット取得開始: userId=$userId');

    try {
      final response = await _supabase.rpc(
        Rpcs.getUserAvailableTickets,
        params: {'p_user_id': userId},
      );

      final List<dynamic> data = response as List<dynamic>;
      final List<AvailableTicket> tickets = data
          .map((json) => AvailableTicket.fromJson(json as Map<String, dynamic>))
          .toList();

      LoggerService.info('利用可能eチケット取得完了: ${tickets.length}件');
      return tickets;
    } catch (error) {
      LoggerService.warn('利用可能eチケット取得に失敗しました: userId=$userId', error);
      rethrow;
    }
  }

  /// ユーザーの利用済みeチケットを取得（14日以内）
  ///
  /// 使用済みで、更新日が14日以内のチケットのみを返します。
  /// RPC関数: get_user_used_tickets
  ///
  /// [userId] ユーザーID (auth.users.id)
  /// Returns 利用済みチケットのリスト（使用日の新しい順）
  Future<List<UsedTicket>> getUserUsedTickets(String userId) async {
    LoggerService.info('利用済みeチケット取得開始: userId=$userId');

    try {
      final response = await _supabase.rpc(
        Rpcs.getUserUsedTickets,
        params: {'p_user_id': userId},
      );

      final List<dynamic> data = response as List<dynamic>;
      final List<UsedTicket> tickets = data
          .map((json) => UsedTicket.fromJson(json as Map<String, dynamic>))
          .toList();

      LoggerService.info('利用済みeチケット取得完了: ${tickets.length}件');
      return tickets;
    } catch (error) {
      LoggerService.warn('利用済みeチケット取得に失敗しました: userId=$userId', error);
      rethrow;
    }
  }
}
