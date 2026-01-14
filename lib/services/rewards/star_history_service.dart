import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/purchase_history.dart';

// 購入履歴を取得するサービスクラス
class StarRewardExpirationDateRetainedStarsHistoriesService {
  StarRewardExpirationDateRetainedStarsHistoriesService(this.supabase);
  final SupabaseClient supabase;

  Future<List<MonthlyPurchaseHistory>> getPurchaseHistory() async {
    try {
      // 現在ログインしているユーザーのIDを取得
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // 購入履歴を取得
      // 一旦ダミーデータを返す
      final response = [
        {
          'id': '',
          'user_id': '',
          'product_name': 'カフェラテ',
          'price': 550,
          'star_points': 5.5,
          'store_name': '渋谷店',
          'card_number': '****-****-****-1234',
          'purchase_datetime': '2025-02-23T05:30:45+00:00',
          'created_at': '2025-02-23T05:30:45+00:00',
        },
        {
          'id': '',
          'user_id': '',
          'product_name': 'カフェラテ',
          'price': 550,
          'star_points': 5.5,
          'store_name': 'Mobile Order',
          'card_number': '****-****-****-1234',
          'purchase_datetime': '2025-02-23T05:30:45+00:00',
          'created_at': '2025-02-23T05:30:45+00:00',
        },
        {
          'id': '',
          'user_id': '',
          'product_name': 'アイスコーヒー',
          'price': 400,
          'star_points': 8.0,
          'store_name': '渋谷店',
          'card_number': '****-****-****-1234',
          'purchase_datetime': '2025-01-23T05:30:45+00:00',
          'created_at': '2025-01-03T05:30:45+00:00',
        },
        {
          'id': '',
          'user_id': '',
          'product_name': 'アイスコーヒー',
          'price': 400,
          'star_points': 8.0,
          'store_name': '渋谷店',
          'card_number': '****-****-****-1234',
          'purchase_datetime': '2024-12-23T05:30:45+00:00',
          'created_at': '2024-12-23T05:30:45+00:00',
        },
        {
          'id': '',
          'user_id': '',
          'product_name': 'アイスコーヒー',
          'price': 400,
          'star_points': 8.0,
          'store_name': '渋谷店',
          'card_number': '****-****-****-1234',
          'purchase_datetime': '2024-12-23T05:30:45+00:00',
          'created_at': '2024-12-23T05:30:45+00:00',
        },
      ];
      // final response = await supabase
      //     .from('purchase_history')
      //     .select()
      //     .eq('user_id', userId)
      //     .order('purchase_datetime', ascending: false);
      // PostgreSQLの日付関数を使用してグルーピング

      // 購入日時で月別にグループ化
      final groupedData = <DateTime, List<PurchaseHistory>>{};

      final List<PurchaseHistory> purchases = (response as List)
          .map((json) => PurchaseHistory.fromJson(json as Map<String, dynamic>))
          .toList();

      for (final purchase in purchases) {
        // 日付から年月のみを取得
        final monthDate = DateTime(purchase.purchaseDateTime.year, purchase.purchaseDateTime.month);

        if (!groupedData.containsKey(monthDate)) {
          groupedData[monthDate] = [];
        }
        groupedData[monthDate]!.add(purchase);
      }

      // レスポンスをモデルクラスに変換
      // MonthlyPurchaseHistory形式に変換して返す
      return groupedData.entries
          .map((entry) => MonthlyPurchaseHistory(month: entry.key, purchases: entry.value))
          .toList()
        ..sort((a, b) => b.month.compareTo(a.month)); // 月で降順ソート
    } catch (e) {
      throw Exception('購入履歴の取得に失敗しました: $e');
    }
  }
}
