import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../constants/supabase_tables.dart';
import '../../../core/services/logger_service.dart';
import '../models/poc_realtime_model.dart';

/// POC Realtime機能の状態を表すクラス
class PocRealtimeState {
  const PocRealtimeState({this.items = const [], this.isLoading = false, this.error});

  final List<PocRealtimeModel> items;
  final bool isLoading;
  final String? error;

  PocRealtimeState copyWith({List<PocRealtimeModel>? items, bool? isLoading, String? error}) {
    return PocRealtimeState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get hasError => error != null;
  bool get isEmpty => items.isEmpty;
}

/// POC Realtime機能のNotifier
class PocRealtimeNotifier extends Notifier<PocRealtimeState> {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  @override
  PocRealtimeState build() {
    // リソースのクリーンアップ
    ref.onDispose(() {
      _channel?.unsubscribe();
    });

    // 初期化
    _initializeRealtime();
    return const PocRealtimeState(isLoading: true);
  }

  /// Realtimeリスナーの初期化
  Future<void> _initializeRealtime() async {
    try {
      // 初期データを取得
      await _fetchInitialData();

      // Realtimeリスナーを設定
      _setupRealtimeListener();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 初期データの取得
  Future<void> _fetchInitialData() async {
    final response = await _supabase
        .from(Tables.pocRealtime)
        .select('id, user_id, created_at')
        .order('created_at', ascending: false);

    final items = (response as List<dynamic>)
        .map((json) => PocRealtimeModel.fromJson(json as Map<String, dynamic>))
        .toList();

    state = state.copyWith(items: items, isLoading: false);
  }

  /// Realtimeリスナーの設定
  void _setupRealtimeListener() {
    LoggerService.info('Realtimeチャンネルを設定中');

    _channel = _supabase
        .channel('poc-realtime-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: Tables.pocRealtime,
          callback: (payload) {
            LoggerService.info('Realtimeイベント受信: ${payload.eventType}');
            _handleRealtimeEvent(payload);
          },
        )
        .subscribe();

    LoggerService.info('Realtimeチャンネルをサブスクライブしました');
  }

  /// Realtimeイベントのハンドリング
  void _handleRealtimeEvent(PostgresChangePayload payload) {
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        _handleInsert(payload.newRecord);
      case PostgresChangeEvent.update:
        _handleUpdate(payload.newRecord);
      case PostgresChangeEvent.delete:
        _handleDelete(payload.oldRecord);
      case PostgresChangeEvent.all:
        break;
    }
  }

  /// INSERTイベントの処理
  void _handleInsert(Map<String, dynamic> record) {
    LoggerService.info('新しいレコードが追加されました: ${record['id']}');
    final newItem = PocRealtimeModel.fromJson(record);
    final updatedItems = [newItem, ...state.items];
    state = state.copyWith(items: updatedItems);
  }

  /// UPDATEイベントの処理
  void _handleUpdate(Map<String, dynamic> record) {
    LoggerService.info('レコードが更新されました: ${record['id']}');
    final updatedItem = PocRealtimeModel.fromJson(record);
    final updatedItems = state.items.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// DELETEイベントの処理
  void _handleDelete(Map<String, dynamic> record) {
    LoggerService.info('レコードが削除されました: ${record['id']}');
    final deletedId = record['id'] as String;
    final updatedItems = state.items.where((item) => item.id != deletedId).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// 新しいレコードを追加
  Future<void> addRecord() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      LoggerService.warn('ユーザーが認証されていません');
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    try {
      LoggerService.info('新しいレコードを追加中: userID=${user.id}');
      await _supabase.from(Tables.pocRealtime).insert({'user_id': user.id});
      LoggerService.info('レコードの追加リクエスト完了');

      // Realtimeで自動的に更新されるため、ここでは何もしない
    } catch (e) {
      LoggerService.warn('レコード追加に失敗しました', e);
      state = state.copyWith(error: e.toString());
    }
  }
}

/// PocRealtimeProviderの定義
final pocRealtimeProvider = NotifierProvider<PocRealtimeNotifier, PocRealtimeState>(
  PocRealtimeNotifier.new,
);
