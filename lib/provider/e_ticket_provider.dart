import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../core/models/user_ticket.dart';
import '../data/repository/e_ticket_repository.dart';
import 'auth_state_provider.dart';

/// 利用可能なeチケットを取得するProvider
///
/// 認証状態に基づいて自動的に更新されます。
/// - ログイン中: ユーザーの利用可能チケットを取得
/// - 未ログイン: 空のリストを返す
final availableTicketsProvider = FutureProvider<List<AvailableTicket>>((ref) async {
  // 認証状態を監視（authStateProviderが変わると自動的に再実行）
  final authState = ref.watch(authStateProvider);

  // ユーザーがログインしていない場合は空のリストを返す
  return authState.when(
    data: (user) async {
      if (user == null) {
        return [];
      }

      // ETicketRepositoryをDIコンテナから取得
      final repository = GetIt.instance<ETicketRepository>();

      // ユーザーIDを使って利用可能チケットを取得
      final tickets = await repository.getUserAvailableTickets(user.id);
      return tickets;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// 利用済みeチケットを取得するProvider（14日以内）
///
/// 認証状態に基づいて自動的に更新されます。
/// - ログイン中: ユーザーの利用済みチケット（14日以内）を取得
/// - 未ログイン: 空のリストを返す
final usedTicketsProvider = FutureProvider<List<UsedTicket>>((ref) async {
  // 認証状態を監視（authStateProviderが変わると自動的に再実行）
  final authState = ref.watch(authStateProvider);

  // ユーザーがログインしていない場合は空のリストを返す
  return authState.when(
    data: (user) async {
      if (user == null) {
        return [];
      }

      // ETicketRepositoryをDIコンテナから取得
      final repository = GetIt.instance<ETicketRepository>();

      // ユーザーIDを使って利用済みチケットを取得
      final tickets = await repository.getUserUsedTickets(user.id);
      return tickets;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// 利用可能なeチケットの枚数を取得するProvider
///
/// ナビゲーションバーのバッジ表示に使用します。
/// - データ取得中またはエラー時: 0を返す
/// - データ取得成功: チケット枚数を返す
final availableTicketCountProvider = Provider<int>((ref) {
  final ticketsAsync = ref.watch(availableTicketsProvider);

  return ticketsAsync.when(
    data: (tickets) => tickets.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
