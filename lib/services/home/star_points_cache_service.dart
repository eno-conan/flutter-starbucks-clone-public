import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/supabase_rpcs.dart';
import '../../core/services/logger_service.dart';
import '../../shared/helpers/local_database.dart';
import '../auth_service.dart';

/// スターポイント数:キャッシュサービスクラス
class StarPointsCacheService {
  StarPointsCacheService({this.cacheDuration = 3600000});
  final supabase = Supabase.instance.client;
  final dbHelper = DatabaseHelper.instance;

  // キャッシュの有効期間（ミリ秒）
  final int cacheDuration; // デフォルト1時間

  // データを取得（キャッシュがあればキャッシュから、なければSupabaseから）
  Future<double> getDataViaFunction(
    String tableName, {
    String? query,
    bool isForceIgnoreCache = false,
  }) async {
    final cacheKey = '${tableName}_${query ?? 'all'}';

    // キャッシュを強制的に無視しない場合のみキャッシュをチェック
    if (!isForceIgnoreCache) {
      final cachedData = await _getCachedData(cacheKey, tableName);
      if (cachedData != null) {
        if (kDebugMode) {
          LoggerService.info('獲得スター数合計の取得（キャッシュ利用）');
          LoggerService.info(cachedData.toString());
        }
        return cachedData;
      }
    }

    // キャッシュがない場合はSupabaseから取得
    if (kDebugMode) {
      LoggerService.info('獲得スター数合計の取得(DBから)');
    }

    try {
      // スターポイントを関数を通じて取得
      final AuthService authService = AuthService();
      authService.getUserId();

      final response = await supabase.rpc<num>(Rpcs.getTotalPointsWithExpirationFlagZero);
      // if (kDebugMode) {
      //   LoggerService.info('スターポイント(DBから): $response');
      // }
      final double data = response.toDouble();

      // 取得したデータをキャッシュに保存
      await _cacheData(cacheKey, data, tableName);

      return data;
    } catch (e) {
      // エラーをログに出力し、再スロー
      if (kDebugMode) {
        LoggerService.warn('Error in getDataViaFunction: $e');
      }
      rethrow;
    }
  }

  // 以下キャッシュサービスの既存メソッド
  Future<double?> _getCachedData(String cacheKey, String tableName) async {
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
    return double.tryParse(cacheItem['data']! as String);
  }

  Future<void> _cacheData(String cacheKey, double data, String tableName) async {
    final db = await dbHelper.database;

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // キャッシュに保存または更新
    await db.insert('cache', {
      'id': cacheKey,
      'data': data.toString(),
      'table_name': tableName,
      'timestamp': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // キャッシュを手動で更新
  Future<double> refreshData(String tableName, {String? query}) async {
    final cacheKey = '${tableName}_${query ?? 'all'}';

    // キャッシュを削除
    final db = await dbHelper.database;
    await db.delete('cache', where: 'id = ?', whereArgs: [cacheKey]);

    // 新しいデータを取得してキャッシュ
    return getDataViaFunction(tableName, query: query);
  }
}
