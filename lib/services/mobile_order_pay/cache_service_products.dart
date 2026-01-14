// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/supabase_buckets.dart';
import '../../constants/supabase_rpcs.dart';
import '../../core/models/product.dart';
import '../../core/services/logger_service.dart';
import '../../shared/helpers/local_database.dart';

/// キャッシュサービスクラス
class ProductsCacheService {
  ProductsCacheService({this.cacheDuration = 86400000});
  final supabase = Supabase.instance.client;
  final dbHelper = DatabaseHelper.instance;

  // キャッシュの有効期間（ミリ秒）
  final int cacheDuration; // デフォルト1日（24時間）

  // アプリセッション中のキャッシュ（スタティック変数でアプリ全体で共有）
  static List<Product>? _sessionCache;
  static bool _isDataLoaded = false;

  // データを取得（キャッシュがあればキャッシュから、なければSupabaseから）
  Future<List<Product>> getData(String tableName, {String? query}) async {
    // アプリセッション中のキャッシュをチェック
    if (_isDataLoaded && _sessionCache != null) {
      if (kDebugMode) {
        LoggerService.info('セッションキャッシュからproductsを取得');
      }
      return List<Product>.from(_sessionCache!);
    }

    final cacheKey = '${tableName}_${query ?? 'all'}';

    // キャッシュがない場合はSupabaseから取得
    if (kDebugMode) {
      LoggerService.info('DBから$tableNameテーブルデータ取得');
    }
    final response = await supabase.rpc(Rpcs.getProductsWithSizesAndCategories);

    // 先にURL取得
    final Map<String, String> pathToUrlMap = await _getSignedUrl(response);

    // URLを含めてJSONに変換
    final List<Product> fetchedProducts = await _setImageUrl(response, pathToUrlMap);

    // 取得したデータをローカルDBキャッシュに保存
    await _cacheData(cacheKey, fetchedProducts, tableName);

    // セッションキャッシュにも保存
    _sessionCache = List<Product>.from(fetchedProducts);
    _isDataLoaded = true;

    return fetchedProducts;
  }

  Future<List<Product>> _setImageUrl(
    List<dynamic> productDataList,
    Map<String, String> pathToUrlMap,
  ) async {
    final List<Product> fetchedProducts = [];
    final Map<int, Map<String, dynamic>> productMap = {};

    // product_id毎にデータをグループ化
    for (final data in productDataList) {
      final productId = data['product_id'] as int;

      if (!productMap.containsKey(productId)) {
        // 新しいproduct_idの場合、基本情報を設定
        final imagePath = data['product_image_path'] as String?;
        String? imageUrl;

        if (imagePath != null && pathToUrlMap.containsKey(imagePath)) {
          imageUrl = pathToUrlMap[imagePath];
        } else {
          imageUrl = 'https://picsum.photos/150/150'; // ダミーURL
        }

        productMap[productId] = {
          'product_id': productId,
          'product_name': data['product_name'],
          'category_id': data['category_id'],
          'category_name': data['category_name'],
          'description': data['description'],
          'product_image_path': data['product_image_path'],
          'sale_type': data['sale_type'],
          'display_order': data['display_order'],
          'image_url': imageUrl,
          'prices': <int>{}, // 価格のSet（重複排除でO(1)）
        };
      }

      // 価格を追加（Set使用で自動的に重複排除）
      final price = data['price'] as int;
      final prices = productMap[productId]!['prices'] as Set<int>;
      prices.add(price);
    }

    // グループ化されたデータからProductオブジェクトを作成
    for (final productData in productMap.values) {
      final productJson = {
        'product_id': productData['product_id'],
        'product_name': productData['product_name'],
        'category_id': productData['category_id'],
        'category_name': productData['category_name'],
        'description': productData['description'],
        'sale_type': productData['sale_type'],
        'display_order': productData['display_order'],
        'image_url': productData['image_url'],
        'price': (productData['prices'] as Set<int>).toList(), // SetからListに変換
      };

      fetchedProducts.add(Product.fromJson(productJson));
    }

    return fetchedProducts;
  }

  Future<Map<String, String>> _getSignedUrl(List<dynamic> productDataList) async {
    final Map<String, String> pathToUrlMap = {};
    final List<String> storagePaths = [];

    for (final data in productDataList) {
      final imagePath = data['product_image_path'] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        storagePaths.add(imagePath);
      }
    }

    try {
      // LoggerService.info(storagePaths);
      if (storagePaths.isNotEmpty) {
        final List<SignedUrl> signedUrls = await supabase.storage
            .from(Buckets.starbucks)
            .createSignedUrls(storagePaths, 60 * 60);
        // LoggerService.info(signedUrls);

        for (int i = 0; i < storagePaths.length; i++) {
          pathToUrlMap[storagePaths[i]] = signedUrls[i].signedUrl;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        LoggerService.warn('Error creating SignedUrls: $e');
      }
    }
    return pathToUrlMap;
  }

  Future<void> _cacheData(String cacheKey, List<Product> data, String tableName) async {
    final db = await dbHelper.database;

    // ProductオブジェクトをJSONに変換
    final dataList = data.map((product) => product.toJson()).toList();
    final dataString = json.encode(dataList);

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
  Future<void> refreshData(String tableName, {String? query}) async {
    // Future<List<Product>> refreshData(String tableName, {String? query}) async {
    final cacheKey = '${tableName}_${query ?? 'all'}';

    // セッションキャッシュをクリア
    _sessionCache = null;
    _isDataLoaded = false;

    // ローカルDBキャッシュを削除
    final db = await dbHelper.database;
    await db.delete('cache', where: 'id = ?', whereArgs: [cacheKey]);

    // 新しいデータを取得してキャッシュ
    // return getData(tableName, query: query);
  }

  // セッションキャッシュをクリアする（アプリ再起動時やデータ更新時に使用）
  static void clearSessionCache() {
    _sessionCache = null;
    _isDataLoaded = false;
  }
}
