import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Notifier クラスに変更
class StoreNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    // 初期状態を返す
    return [];
  }

  // Supabase からデータを取得して保存する
  Future<void> fetchStores() async {
    final response = await supabase.from('stores').select();
    state = response;
  }
}

// NotifierProvider を作成
final storeProvider = NotifierProvider<StoreNotifier, List<Map<String, dynamic>>>(
  StoreNotifier.new,
);
