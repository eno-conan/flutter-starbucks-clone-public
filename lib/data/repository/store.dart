import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/supabase_rpcs.dart';
import '../../core/models/store_mobile_order.dart';
import '../../shared/helpers/local_database.dart';

///店舗テーブルのDB操作
class StoreRepository {
  StoreRepository(this._supabase);
  final SupabaseClient _supabase;
  final _dbHelper = DatabaseHelper.instance;

  // キャッシュの有効期間（ミリ秒）
  final int _cacheDuration = 86400000; // デフォルト1日（24時間）

  /// 近隣の店舗を取得
  Future<List<StoreMobileOrder>> getNearbyStores(
    double latitude,
    double longitude, {
    double radiusKm = 30.0,
  }) async {
    final response = await _supabase.rpc(
      Rpcs.getNearbyStores,
      params: {'lat': latitude, 'lng': longitude, 'radius_km': radiusKm},
    );
    final List<dynamic> data = response as List<dynamic>;
    final List<StoreMobileOrder> stores = data
        .map((json) => StoreMobileOrder.fromJson(json as Map<String, dynamic>))
        .toList();
    return stores;
  }

  /// 全店舗データを取得（キャッシュ対応）
  Future<List<Map<String, dynamic>>> getAllStores() async {
    const cacheKey = 'stores_all';

    // ローカルキャッシュをチェック
    final cachedStores = await _loadFromLocalCache(cacheKey);
    if (cachedStores != null) {
      return cachedStores;
    }

    // キャッシュがない場合はSupabaseから取得
    if (kDebugMode) {
      debugPrint('DBからstoresテーブルデータ取得');
    }

    // 実際のSupabaseクエリを実装する場合はここに追加
    // 現在はダミーデータを返す
    final List<Map<String, dynamic>> storeData = [];

    // 取得したデータをローカルキャッシュに保存
    await _cacheData(cacheKey, storeData);

    return storeData;
  }

  /// お気に入り店舗番号のリストを取得
  Future<List<String>> getFavoriteStoreNumbers() async {
    final db = await _dbHelper.database;

    final result = await db.query('favorite_stores', orderBy: 'created_at DESC');

    if (result.isEmpty) {
      return [];
    }

    // 店舗番号のみを取得
    return result.map((item) => item['store_number']! as String).toList();
  }

  /// お気に入り店舗の詳細情報を取得
  Future<List<StoreMobileOrder>> getFavoriteStores() async {
    final favoriteStoreNumbers = await getFavoriteStoreNumbers();

    if (favoriteStoreNumbers.isEmpty) {
      return [];
    }

    // 全店舗データを取得
    final allStores = await getAllStores();

    // お気に入りの店舗だけをフィルタリング（Set使用でO(1)検索に最適化）
    final favoriteStoreNumbersSet = favoriteStoreNumbers.toSet();
    final favoriteStoresData = allStores.where((store) {
      final storeNumber = store['store_number']?.toString() ?? '';
      return favoriteStoreNumbersSet.contains(storeNumber);
    }).toList();

    // Map<String, dynamic>からStoreMobileOrderオブジェクトに変換
    return favoriteStoresData.map((json) => StoreMobileOrder.fromJson(json)).toList();
  }

  /// 店舗がお気に入りに登録されているか確認
  Future<bool> isStoreFavorite(String storeNumber) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'favorite_stores',
      where: 'store_number = ?',
      whereArgs: [storeNumber],
    );

    return result.isNotEmpty;
  }

  /// お気に入り店舗を追加
  Future<void> addFavoriteStore(String storeNumber) async {
    final db = await _dbHelper.database;

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await db.insert('favorite_stores', {
      'store_number': storeNumber,
      'created_at': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// お気に入り店舗を削除
  Future<void> removeFavoriteStore(String storeNumber) async {
    final db = await _dbHelper.database;

    await db.delete('favorite_stores', where: 'store_number = ?', whereArgs: [storeNumber]);
  }

  /// すべてのお気に入り店舗を削除
  Future<void> clearAllFavorites() async {
    final db = await _dbHelper.database;
    await db.delete('favorite_stores');
  }

  /// ローカルキャッシュから読み込み
  Future<List<Map<String, dynamic>>?> _loadFromLocalCache(String cacheKey) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query('cache', where: 'id = ?', whereArgs: [cacheKey]);

      if (result.isNotEmpty) {
        final cacheData = result.first;
        final timestamp = cacheData['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;

        // キャッシュの有効期限をチェック
        if (now - timestamp < _cacheDuration) {
          final dataString = cacheData['data'] as String;
          final List<dynamic> jsonList = jsonDecode(dataString);
          return jsonList.cast<Map<String, dynamic>>();
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading from local cache: $e');
      }
      return null;
    }
  }

  /// データをローカルキャッシュに保存
  Future<void> _cacheData(String cacheKey, List<Map<String, dynamic>> data) async {
    final db = await _dbHelper.database;

    final dataString = json.encode(data);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // キャッシュに保存または更新
    await db.insert('cache', {
      'id': cacheKey,
      'data': dataString,
      'table_name': 'stores',
      'timestamp': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 店舗番号から閉店時刻を取得
  Future<TimeOfDay?> getStoreClosingTime(String storeNumber) async {
    try {
      final response = await _supabase
          .from('stores')
          .select('closing_time')
          .eq('store_number', storeNumber)
          .single();

      if (response['closing_time'] != null) {
        final closingTimeStr = response['closing_time'] as String;
        final closingHour = int.parse(closingTimeStr.split(':')[0]);
        final closingMinute = int.parse(closingTimeStr.split(':')[1]);
        return TimeOfDay(hour: closingHour, minute: closingMinute);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('閉店時刻の取得中にエラーが発生しました: $e');
      }
      return null;
    }
  }

  /// 閉店15分前以降かどうかをチェック（閉店時刻を過ぎている場合も含む）
  bool isWithin15MinutesBeforeClosing(TimeOfDay closingTime) {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    // 現在時刻と閉店時刻を分単位に変換
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final closingMinutes = closingTime.hour * 60 + closingTime.minute;

    // 閉店時刻の15分前を計算
    final closingMinus15Minutes = closingMinutes - 15;

    // 現在時刻が閉店15分前以降かチェック（閉店時刻を過ぎている場合も注文不可）
    return currentMinutes >= closingMinus15Minutes;
  }
}
