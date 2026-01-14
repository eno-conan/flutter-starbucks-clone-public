import 'package:flutter/foundation.dart';

import 'performance_monitoring_service.dart';

/// データ読み込み操作のパフォーマンス計測を簡素化するヘルパー
///
/// Usage:
/// ```dart
/// final products = await DataLoadingPerformanceHelper.measureDataLoad(
///   'products_data_load',
///   () => _cacheService.getData('products'),
///   cacheInfo: CacheInfo(
///     usedCache: true,
///     cacheType: 'shared_preferences',
///   ),
///   dataInfo: DataInfo(
///     itemCount: products.length,
///     dataType: 'products',
///   ),
/// );
/// ```
class DataLoadingPerformanceHelper {
  static final _performanceService = PerformanceMonitoringService();

  /// データ読み込み処理のパフォーマンス計測
  static Future<T> measureDataLoad<T>(
    String operationName,
    Future<T> Function() dataLoadFunction, {
    CacheInfo? cacheInfo,
    DataInfo? dataInfo,
    Map<String, String>? additionalAttributes,
  }) async {
    return _performanceService.measureAsync(
      operationName,
      () async {
        final result = await dataLoadFunction();

        // 結果に基づいて追加のメトリクスを設定
        if (dataInfo != null) {
          _performanceService.addMetric(operationName, 'data_item_count', dataInfo.itemCount);
          if (dataInfo.dataSize != null) {
            _performanceService.addMetric(operationName, 'data_size_bytes', dataInfo.dataSize!);
          }
        }

        return result;
      },
      attributes: {
        if (cacheInfo != null) ...{
          'used_cache': cacheInfo.usedCache.toString(),
          'cache_type': cacheInfo.cacheType,
          if (cacheInfo.cacheHitRatio != null)
            'cache_hit_ratio': cacheInfo.cacheHitRatio!.toStringAsFixed(2),
        },
        if (dataInfo != null) ...{
          'data_type': dataInfo.dataType,
          if (dataInfo.source != null) 'data_source': dataInfo.source!,
        },
        ...?additionalAttributes,
      },
      metrics: {
        if (cacheInfo != null && cacheInfo.usedCache) 'used_cache': 1 else 'used_api': 1,
        'load_success': 1,
      },
    );
  }

  /// エラー情報付きでデータ読み込み処理を計測
  static Future<T> measureDataLoadWithErrorHandling<T>(
    String operationName,
    Future<T> Function() dataLoadFunction,
    T Function(Object error, StackTrace stackTrace) fallbackFunction, {
    CacheInfo? cacheInfo,
    DataInfo? dataInfo,
    Map<String, String>? additionalAttributes,
  }) async {
    try {
      return await measureDataLoad(
        operationName,
        dataLoadFunction,
        cacheInfo: cacheInfo,
        dataInfo: dataInfo,
        additionalAttributes: additionalAttributes,
      );
    } catch (error, stackTrace) {
      debugPrint('Data load error in $operationName: $error');

      _performanceService.addMetric(operationName, 'load_error', 1);
      _performanceService.addAttribute(operationName, 'error_type', error.runtimeType.toString());

      final fallbackResult = fallbackFunction(error, stackTrace);
      _performanceService.addMetric(operationName, 'fallback_used', 1);

      return fallbackResult;
    }
  }

  /// 画像読み込み専用の計測
  static Future<void> measureImageLoad(String imageUrl, {String? productId}) async {
    await _performanceService.measureAsync(
      'image_load',
      () => Future.delayed(Duration.zero), // 実際の画像読み込みは外部で処理
      attributes: {
        'image_url_domain': Uri.tryParse(imageUrl)?.host ?? 'unknown',
        if (productId != null) 'product_id': productId,
      },
      metrics: {'image_load_attempt': 1},
    );
  }

  /// 画像読み込みエラーを記録
  static void recordImageLoadError(String imageUrl, {String? errorMessage}) {
    _performanceService.measureSync(
      'image_load_error',
      () => null,
      attributes: {
        'image_url_domain': Uri.tryParse(imageUrl)?.host ?? 'unknown',
        if (errorMessage != null) 'error_message': errorMessage,
      },
      metrics: {'image_load_error': 1},
    );
  }

  /// バックグラウンドでのキャッシュ更新を計測
  static Future<void> measureBackgroundCacheUpdate(
    String dataType,
    Future<void> Function() updateFunction,
  ) async {
    await _performanceService.measureAsync(
      'background_cache_update',
      updateFunction,
      attributes: {'data_type': dataType, 'update_mode': 'background'},
      metrics: {'cache_update_attempt': 1},
    );
  }
}

/// キャッシュ情報
class CacheInfo {
  const CacheInfo({required this.usedCache, required this.cacheType, this.cacheHitRatio});
  final bool usedCache;
  final String cacheType;
  final double? cacheHitRatio;
}

/// データ情報
class DataInfo {
  const DataInfo({required this.itemCount, required this.dataType, this.source, this.dataSize});
  final int itemCount;
  final String dataType;
  final String? source;
  final int? dataSize;
}
