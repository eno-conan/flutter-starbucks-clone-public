// データベースヘルパークラス
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/models/store_mobile_order.dart';
import '../../core/services/logger_service.dart';

/// ローカルDBヘルパークラス
class DatabaseHelper {
  DatabaseHelper._init();
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB('supabase_cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // キャッシュテーブル (既存)
    await db.execute('''
      CREATE TABLE cache (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        table_name TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // お気に入り店舗テーブル
    await db.execute('''
      CREATE TABLE favorite_stores (
        store_number TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL
      )
    ''');

    // 検索履歴テーブル
    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        search_data TEXT NOT NULL,
        searched_at INTEGER NOT NULL
      )
    ''');
  }

  // 保存時
  Future<void> saveSearchHistory(StoreMobileOrder order) async {
    final db = await database;
    await db.insert('search_history', {
      'search_data': jsonEncode({
        'store_number': order.storeNumber,
        'store_name': order.storeName,
        'address': order.address,
        'latitude': order.latitude,
        'longitude': order.longitude,
        'opening_time': order.openingTime != null
            ? '${order.openingTime!.hour.toString().padLeft(2, '0')}:${order.openingTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'closing_time': order.closingTime != null
            ? '${order.closingTime!.hour.toString().padLeft(2, '0')}:${order.closingTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'distance_km': order.distance,
      }),
      'searched_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // 取得時
  Future<List<StoreMobileOrder>> getRecentSearchHistory() async {
    final db = await database;
    final result = await db.query(
      'search_history',
      columns: ['search_data'],
      orderBy: 'searched_at DESC',
      limit: 10,
    );
    final tempList = result.map((row) {
      final jsonData = jsonDecode(row['search_data']! as String) as Map<String, dynamic>;
      return StoreMobileOrder.fromJson(jsonData);
    }).toList();
    if (kDebugMode) {
      LoggerService.info('Converted search history: $tempList');
    }
    return tempList;
  }

  /// すべての検索履歴を削除
  Future<void> clearAllSearchHistory() async {
    final db = await database;
    await db.delete('search_history');
  }

  // データベースのバージョンアップグレード時の処理
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // バージョン1から2へのアップグレード
      await db.execute('''
        CREATE TABLE favorite_stores (
          store_number TEXT PRIMARY KEY,
          created_at INTEGER NOT NULL
        )
      ''');
    }
  }
}
