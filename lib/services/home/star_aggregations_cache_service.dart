import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/supabase_tables.dart';
import '../../core/services/logger_service.dart';
import '../../shared/helpers/local_database.dart';

/// 星集計データ用キャッシュサービスクラス
class StarAggregationsCacheService {
  StarAggregationsCacheService({this.cacheDuration = 3600000});
  final supabase = Supabase.instance.client;
  final dbHelper = DatabaseHelper.instance;

  // キャッシュの有効期間（ミリ秒）
  final int cacheDuration; // デフォルト1時間

  // 星集計データを取得（キャッシュがあればキャッシュから、なければSupabaseから）
  Future<List<Map<String, dynamic>>> getStarAggregations() async {
    const tableName = Tables.starAggregations;
    const cacheKey = '${tableName}_ordered_data';

    // キャッシュをチェック
    final cachedData = await _getCachedData(cacheKey, tableName);
    if (cachedData != null) {
      if (kDebugMode) {
        LoggerService.info('キャッシュから星集計データ取得を実施');
      }
      return cachedData;
    }

    // キャッシュがない場合はSupabaseから取得
    List<Map<String, dynamic>> data;
    if (kDebugMode) {
      LoggerService.info('DBから星集計データ取得を実施');
    }

    // 現在のユーザーIDを取得
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ユーザーが認証されていません');
    }

    // star_aggregationsテーブルからデータを取得
    final response = await supabase
        .from(tableName)
        .select('target_year_month, total_points, expiration_datetime')
        .eq('user_id', userId)
        .order('target_year_month', ascending: true);

    data = response;

    // 取得したデータをキャッシュに保存
    await _cacheData(cacheKey, data, tableName);

    return data;
  }

  // キャッシュからデータを取得
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

  // データをキャッシュに保存
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
  Future<List<Map<String, dynamic>>> refreshStarAggregations() async {
    const tableName = 'star_aggregations';
    const cacheKey = '${tableName}_ordered_data';

    // キャッシュを削除
    final db = await dbHelper.database;
    await db.delete('cache', where: 'id = ?', whereArgs: [cacheKey]);

    // 新しいデータを取得してキャッシュ
    return getStarAggregations();
  }

  // 特定のユーザーIDのデータを取得（管理者向け機能など）
  Future<List<Map<String, dynamic>>> getStarAggregationsByUserId(String userId) async {
    const tableName = 'star_aggregations';
    final cacheKey = '${tableName}_user_$userId';

    // キャッシュをチェック
    final cachedData = await _getCachedData(cacheKey, tableName);
    if (cachedData != null) {
      if (kDebugMode) {
        LoggerService.info('キャッシュから特定ユーザーの星集計データ取得を実施');
      }
      return cachedData;
    }

    // キャッシュがない場合はSupabaseから取得
    List<Map<String, dynamic>> data;
    if (kDebugMode) {
      LoggerService.info('DBから特定ユーザーの星集計データ取得を実施');
    }

    // star_aggregationsテーブルからデータを取得
    final response = await supabase
        .from(Tables.starAggregations)
        .select('target_year_month, total_points, expiration_datetime')
        .eq('user_id', userId)
        .order('target_year_month', ascending: true);

    data = response;

    // 取得したデータをキャッシュに保存
    await _cacheData(cacheKey, data, tableName);

    return data;
  }
}
