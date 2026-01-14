import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/supabase_buckets.dart';
import '../../constants/supabase_rpcs.dart';
import '../../core/models/product.dart';
import '../../core/services/logger_service.dart';
import '../../shared/helpers/local_database.dart';

///商品テーブルのDB操作
class ProductRepository {
  ProductRepository(this._supabase);
  final SupabaseClient _supabase;
  final _dbHelper = DatabaseHelper.instance;

  // キャッシュの有効期間（ミリ秒）
  final int _cacheDuration = 86400000; // デフォルト1日（24時間）

  // アプリセッション中のキャッシュ（スタティック変数でアプリ全体で共有）
  static List<Product>? _sessionCache;
  static bool _isDataLoaded = false;

  /// 商品一覧を取得（キャッシュ優先）
  Future<List<Product>> getProducts() async {
    // アプリセッション中のキャッシュをチェック
    if (_isDataLoaded && _sessionCache != null) {
      if (kDebugMode) {
        LoggerService.info('セッションキャッシュからproductsを取得');
      }
      return List<Product>.from(_sessionCache!);
    }

    const cacheKey = 'products_all';

    // ローカルDBキャッシュをチェック
    final cachedProducts = await _loadFromLocalCache(cacheKey);
    if (cachedProducts != null && cachedProducts.isNotEmpty) {
      _sessionCache = List<Product>.from(cachedProducts);
      _isDataLoaded = true;
      return cachedProducts;
    }

    // キャッシュがない場合はSupabaseから取得
    if (kDebugMode) {
      LoggerService.info('DBからproductsテーブルデータ取得');
    }
    final response = await _supabase.rpc(Rpcs.getProductsWithSizesAndCategories);

    // 先にURL取得
    final Map<String, String> pathToUrlMap = await _getSignedUrl(response);

    // URLを含めてJSONに変換
    final List<Product> fetchedProducts = await _setImageUrl(response, pathToUrlMap);

    // 取得したデータをローカルDBキャッシュに保存
    await _cacheData(cacheKey, fetchedProducts);

    // セッションキャッシュにも保存
    _sessionCache = List<Product>.from(fetchedProducts);
    _isDataLoaded = true;

    return fetchedProducts;
  }

  /// 特定のIDの商品を取得
  Future<Product?> getProductById(int productId) async {
    final products = await getProducts();
    try {
      return products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// カテゴリ別の商品を取得
  Future<Map<String, List<Product>>> getProductsByCategory() async {
    final products = await getProducts();
    final Map<String, List<Product>> grouped = {};
    
    for (final product in products) {
      final category = product.category.isEmpty ? 'その他' : product.category;
      if (grouped[category] == null) {
        grouped[category] = [];
      }
      grouped[category]!.add(product);
    }
    
    return grouped;
  }

  /// キャッシュを手動で更新
  Future<void> refreshData() async {
    const cacheKey = 'products_all';

    // セッションキャッシュをクリア
    _sessionCache = null;
    _isDataLoaded = false;

    // ローカルDBキャッシュを削除
    final db = await _dbHelper.database;
    await db.delete('cache', where: 'id = ?', whereArgs: [cacheKey]);
  }

  /// セッションキャッシュをクリア
  static void clearSessionCache() {
    _sessionCache = null;
    _isDataLoaded = false;
  }

  /// ローカルキャッシュから読み込み
  Future<List<Product>?> _loadFromLocalCache(String cacheKey) async {
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
          return jsonList.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
        }
      }

      return null;
    } catch (e) {
      LoggerService.info('Error loading from local cache: $e');
      return null;
    }
  }

  /// 商品データにImageURLを設定
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

  /// ストレージからサインドURLを取得
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
      if (storagePaths.isNotEmpty) {
        final List<SignedUrl> signedUrls = await _supabase.storage
            .from(Buckets.starbucks)
            .createSignedUrls(storagePaths, 60 * 60);

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

  /// データをローカルキャッシュに保存
  Future<void> _cacheData(String cacheKey, List<Product> data) async {
    final db = await _dbHelper.database;

    // ProductオブジェクトをJSONに変換
    final dataList = data.map((product) => product.toJson()).toList();
    final dataString = json.encode(dataList);

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // キャッシュに保存または更新
    await db.insert('cache', {
      'id': cacheKey,
      'data': dataString,
      'table_name': 'products',
      'timestamp': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}