import 'dart:async';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Firebase Performance monitoring を共通化するサービス
/// AOP（Aspect-Oriented Programming）ライクな実装で
/// パフォーマンス計測のボイラープレートコードを削減
class PerformanceMonitoringService {
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();
  static final PerformanceMonitoringService _instance = PerformanceMonitoringService._internal();

  /// アクティブなトレースを管理（メモリリーク防止）
  final Map<String, Trace> _activeTraces = {};

  /// 計測付き関数実行（同期）
  ///
  /// Usage:
  /// ```dart
  /// final result = PerformanceMonitoringService().measureSync(
  ///   'button_tap',
  ///   () => _handleButtonTap(),
  ///   attributes: {'button_id': 'submit'},
  ///   metrics: {'tap_count': 1},
  /// );
  /// ```
  T measureSync<T>(
    String traceName,
    T Function() function, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) {
    final trace = FirebasePerformance.instance.newTrace(traceName);

    try {
      trace.start();
      _addAttributesAndMetrics(trace, attributes, metrics);

      final result = function();

      trace.incrementMetric('execution_success', 1);
      return result;
    } catch (e, stackTrace) {
      trace.incrementMetric('execution_error', 1);
      debugPrint('Performance trace error in $traceName: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    } finally {
      trace.stop();
    }
  }

  /// 計測付き関数実行（非同期）
  ///
  /// Usage:
  /// ```dart
  /// final result = await PerformanceMonitoringService().measureAsync(
  ///   'data_load',
  ///   () => _loadData(),
  ///   attributes: {'data_type': 'products'},
  /// );
  /// ```
  Future<T> measureAsync<T>(
    String traceName,
    Future<T> Function() function, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) async {
    final trace = FirebasePerformance.instance.newTrace(traceName);

    try {
      await trace.start();
      _addAttributesAndMetrics(trace, attributes, metrics);

      final result = await function();

      trace.incrementMetric('execution_success', 1);
      return result;
    } catch (e, stackTrace) {
      trace.incrementMetric('execution_error', 1);
      debugPrint('Performance trace error in $traceName: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  /// 手動トレース開始（長時間実行される処理用）
  ///
  /// Usage:
  /// ```dart
  /// PerformanceMonitoringService().startTrace('app_session');
  /// // ... 長時間の処理
  /// PerformanceMonitoringService().stopTrace('app_session');
  /// ```
  Future<void> startTrace(
    String traceName, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) async {
    if (_activeTraces.containsKey(traceName)) {
      debugPrint('Warning: Trace $traceName is already active');
      return;
    }

    final trace = FirebasePerformance.instance.newTrace(traceName);
    await trace.start();
    _addAttributesAndMetrics(trace, attributes, metrics);

    _activeTraces[traceName] = trace;
  }

  /// 手動トレース停止
  Future<void> stopTrace(
    String traceName, {
    Map<String, String>? additionalAttributes,
    Map<String, int>? additionalMetrics,
  }) async {
    final trace = _activeTraces.remove(traceName);
    if (trace == null) {
      debugPrint('Warning: No active trace found for $traceName');
      return;
    }

    _addAttributesAndMetrics(trace, additionalAttributes, additionalMetrics);
    await trace.stop();
  }

  /// アクティブなトレースにメトリクスを追加
  void addMetric(String traceName, String metricName, int value) {
    final trace = _activeTraces[traceName];
    if (trace == null) {
      debugPrint('Warning: No active trace found for $traceName');
      return;
    }
    trace.incrementMetric(metricName, value);
  }

  /// アクティブなトレースに属性を追加
  void addAttribute(String traceName, String attributeName, String value) {
    final trace = _activeTraces[traceName];
    if (trace == null) {
      debugPrint('Warning: No active trace found for $traceName');
      return;
    }
    trace.putAttribute(attributeName, value);
  }

  /// 全てのアクティブなトレースを停止（アプリ終了時など）
  Future<void> stopAllTraces() async {
    final traces = Map<String, Trace>.from(_activeTraces);
    _activeTraces.clear();

    await Future.wait(traces.values.map((trace) => trace.stop()));
  }

  /// トレースに属性とメトリクスを追加する共通処理
  void _addAttributesAndMetrics(
    Trace trace,
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  ) {
    attributes?.forEach((key, value) {
      trace.putAttribute(key, value);
    });

    metrics?.forEach((key, value) {
      trace.incrementMetric(key, value);
    });
  }
}

/// Extension methods for easier usage
extension AsyncFunctionPerformanceMonitoring<T> on Future<T> Function() {
  /// 非同期関数にパフォーマンス計測を追加
  ///
  /// Usage:
  /// ```dart
  /// final result = await (() => _loadData()).withPerformanceMonitoring(
  ///   'products_load',
  ///   attributes: {'category': 'drinks'},
  /// );
  /// ```
  Future<T> withPerformanceMonitoring(
    String traceName, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) {
    return PerformanceMonitoringService().measureAsync(
      traceName,
      this,
      attributes: attributes,
      metrics: metrics,
    );
  }
}

extension SyncFunctionPerformanceMonitoring<T> on T Function() {
  /// 同期関数にパフォーマンス計測を追加
  ///
  /// Usage:
  /// ```dart
  /// final result = (() => _processData()).withPerformanceMonitoring(
  ///   'data_processing',
  ///   metrics: {'item_count': 100},
  /// );
  /// ```
  T withPerformanceMonitoring(
    String traceName, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) {
    return PerformanceMonitoringService().measureSync(
      traceName,
      this,
      attributes: attributes,
      metrics: metrics,
    );
  }
}
