// ダミーデータを提供するサービスクラス
import 'package:sqflite/sqflite.dart';

import '../../../core/models/favorite_store.dart';
import '../../../core/models/store_mobile_order.dart';
import '../../../shared/helpers/local_database.dart';
import 'store_cache_service.dart';

// お気に入り店舗サービスクラス
class FavoriteStoreService {
  final dbHelper = DatabaseHelper.instance;

  // お気に入り店舗番号のリストを取得
  Future<List<String>> getFavoriteStoreNumbers() async {
    final db = await dbHelper.database;

    final result = await db.query('favorite_stores', orderBy: 'created_at DESC');

    if (result.isEmpty) {
      return [];
    }

    // 店舗番号のみを取得
    return result.map((item) => item['store_number']! as String).toList();
  }

  // お気に入り店舗の詳細情報を取得（キャッシュサービスと連携）
  Future<List<StoreMobileOrder>> getFavoriteStores(StoreCacheService cacheService) async {
    final favoriteStoreNumbers = await getFavoriteStoreNumbers();

    if (favoriteStoreNumbers.isEmpty) {
      return [];
    }

    // 全店舗データを取得
    final allStores = await cacheService.getData('stores');

    // お気に入りの店舗だけをフィルタリング（Set使用でO(1)検索に最適化）
    final favoriteStoreNumbersSet = favoriteStoreNumbers.toSet();
    final favoriteStoresData = allStores.where((store) {
      final storeNumber = store['store_number']?.toString() ?? '';
      return favoriteStoreNumbersSet.contains(storeNumber);
    }).toList();

    // Map<String, dynamic>からStoreMobileOrderオブジェクトに変換
    return favoriteStoresData.map((json) => StoreMobileOrder.fromJson(json)).toList();
  }

  // 店舗がお気に入りに登録されているか確認
  Future<bool> isStoreFavorite(String storeNumber) async {
    final db = await dbHelper.database;

    final result = await db.query(
      'favorite_stores',
      where: 'store_number = ?',
      whereArgs: [storeNumber],
    );

    return result.isNotEmpty;
  }

  // お気に入り店舗を追加
  Future<void> addFavoriteStore(String storeNumber) async {
    final db = await dbHelper.database;

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await db.insert('favorite_stores', {
      'store_number': storeNumber,
      'created_at': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // お気に入り店舗を削除
  Future<void> removeFavoriteStore(String storeNumber) async {
    final db = await dbHelper.database;

    await db.delete('favorite_stores', where: 'store_number = ?', whereArgs: [storeNumber]);
  }

  // すべてのお気に入り店舗を削除
  Future<void> clearAllFavorites() async {
    final db = await dbHelper.database;
    await db.delete('favorite_stores');
  }
}

class FavoriteStoreServiceOld {
  // 実際はHTTP通信でデータを取得する部分
  Future<List<FavoriteStore>> getFavoriteStoresDummy() async {
    // HTTP通信の代わりに少し遅延を入れてAsyncの挙動を再現
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // ダミーデータを返す
    return [
      FavoriteStore(
        id: 'store1',
        name: '錦糸町パルコ店',
        address: '東京都 墨田区 江東橋4-27-14',
        waitTime: '約5～10分後',
        lastOrderTime: '21:30',
        distance: '1.0km',
      ),
      FavoriteStore(
        id: 'store2',
        name: '秋葉原UDX店',
        address: '東京都 千代田区 外神田4-14-1',
        waitTime: '約3～8分後',
        lastOrderTime: '22:00',
        distance: '1.5km',
      ),
      FavoriteStore(
        id: 'store3',
        name: '東京スカイツリータウン・ソラマチ店',
        address: '東京都 墨田区 押上1-1-2',
        waitTime: '約10～15分後',
        lastOrderTime: '21:00',
        distance: '2.3km',
      ),
    ];
  }
}
