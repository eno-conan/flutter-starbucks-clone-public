import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../constants/supabase_tables.dart';
import '../../../shared/helpers/local_database.dart';

/// キャッシュサービスクラス
class StoreCacheService {
  StoreCacheService({this.cacheDuration = 3600000});
  final supabase = Supabase.instance.client;
  final dbHelper = DatabaseHelper.instance;

  // キャッシュの有効期間（ミリ秒）
  final int cacheDuration; // デフォルト1時間

  // データを取得（キャッシュがあればキャッシュから、なければSupabaseから）
  Future<List<Map<String, dynamic>>> getData(String tableName, {String? query}) async {
    final cacheKey = '${tableName}_${query ?? 'all'}';

    // キャッシュをチェック
    final cachedData = await _getCachedData(cacheKey, tableName);
    if (cachedData != null) {
      if (kDebugMode) {
        debugPrint('キャッシュからstoresデータ取得を実施');
        // debugPrint(cachedData);
      }
      return cachedData;
    }

    // キャッシュがない場合はSupabaseから取得
    List<Map<String, dynamic>> data;
    if (kDebugMode) {
      debugPrint('DBからstoresテーブルデータ取得を実施');
    }
    final response = await supabase.from(Tables.stores).select();
    data = response;

    // 取得したデータをキャッシュに保存
    await _cacheData(cacheKey, data, tableName);

    return data;
  }

  // 以下キャッシュサービスの既存メソッド
  Future<List<Map<String, dynamic>>?> _getCachedData(String cacheKey, String tableName) async {
    final db = await dbHelper.database;

    final result = await db.query(
      'cache',
      where: 'id = ? AND table_name = ?',
      whereArgs: [cacheKey, tableName],
    );

    if (result.isEmpty) {
      return null;
    }

    final cacheItem = result.first;
    final timestamp = cacheItem['timestamp']! as int;
    final now = DateTime.now().millisecondsSinceEpoch;

    // キャッシュが有効期限切れかチェック
    if (now - timestamp > cacheDuration) {
      // 期限切れの場合は削除
      await db.delete('cache', where: 'id = ?', whereArgs: [cacheKey]);
      return null;
    }

    // キャッシュが有効なら返す
    final dataString = cacheItem['data']! as String;
    final List<dynamic> decodedData = json.decode(dataString);
    return decodedData.cast<Map<String, dynamic>>();
  }

  Future<void> _cacheData(
    String cacheKey,
    List<Map<String, dynamic>> data,
    String tableName,
  ) async {
    final db = await dbHelper.database;

    final dataString = json.encode(data);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // キャッシュに保存または更新
    await db.insert('cache', {
      'id': cacheKey,
      'data': dataString,
      'table_name': tableName,
      'timestamp': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // キャッシュを手動で更新
  Future<List<Map<String, dynamic>>> refreshData(String tableName, {String? query}) async {
    final cacheKey = '${tableName}_${query ?? 'all'}';

    // キャッシュを削除
    final db = await dbHelper.database;
    await db.delete('cache', where: 'id = ?', whereArgs: [cacheKey]);

    // 新しいデータを取得してキャッシュ
    return getData(tableName, query: query);
  }
}
