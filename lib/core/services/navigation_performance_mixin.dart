import 'package:flutter/widgets.dart';
import 'performance_monitoring_service.dart';

/// ナビゲーション操作のパフォーマンス計測を自動化するMixin
///
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with NavigationPerformanceMixin {
///   void _onTap() {
///     measureNavigation(
///       'product_detail_navigation',
///       () => context.go('/product/123'),
///       attributes: {'product_id': '123'},
///     );
///   }
/// }
/// ```
mixin NavigationPerformanceMixin<T extends StatefulWidget> on State<T> {
  final _performanceService = PerformanceMonitoringService();

  /// ナビゲーション操作を計測
  void measureNavigation(
    String actionName,
    VoidCallback navigationAction, {
    Map<String, String>? attributes,
  }) {
    _performanceService.measureSync(
      'navigation_$actionName',
      () {
        navigationAction();
        return null;
      },
      attributes: {
        'widget_type': T.toString(),
        'route_name': ModalRoute.of(context)?.settings.name ?? 'unknown',
        ...?attributes,
      },
      metrics: {'navigation_performed': 1},
    );
  }

  /// 非同期ナビゲーション操作を計測
  Future<void> measureAsyncNavigation(
    String actionName,
    Future<void> Function() navigationAction, {
    Map<String, String>? attributes,
  }) async {
    await _performanceService.measureAsync(
      'async_navigation_$actionName',
      navigationAction,
      attributes: {
        'widget_type': T.toString(),
        'route_name': ModalRoute.of(context)?.settings.name ?? 'unknown',
        ...?attributes,
      },
      metrics: {'navigation_performed': 1},
    );
  }

  /// タブナビゲーション専用の計測
  void measureTabNavigation(int tabIndex) {
    _performanceService.measureSync(
      'bottom_navigation_tap',
      () => null,
      attributes: {'tab_index': tabIndex.toString(), 'widget_type': T.toString()},
      metrics: {'navigation_performed': 1},
    );
  }
}

/// UI操作のパフォーマンス計測を自動化するMixin
///
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with UIPerformanceMixin {
///   void _onButtonPressed() {
///     measureUIAction(
///       'submit_button',
///       () => _handleSubmit(),
///       attributes: {'form_type': 'login'},
///     );
///   }
/// }
/// ```
mixin UIPerformanceMixin<T extends StatefulWidget> on State<T> {
  final _performanceService = PerformanceMonitoringService();

  /// UI操作を計測
  R measureUIAction<R>(String actionName, R Function() action, {Map<String, String>? attributes}) {
    return _performanceService.measureSync(
      'ui_action_$actionName',
      action,
      attributes: {
        'widget_type': T.toString(),
        'route_name': ModalRoute.of(context)?.settings.name ?? 'unknown',
        ...?attributes,
      },
      metrics: {'action_performed': 1},
    );
  }

  /// 非同期UI操作を計測
  Future<R> measureAsyncUIAction<R>(
    String actionName,
    Future<R> Function() action, {
    Map<String, String>? attributes,
  }) async {
    return _performanceService.measureAsync(
      'async_ui_action_$actionName',
      action,
      attributes: {
        'widget_type': T.toString(),
        'route_name': ModalRoute.of(context)?.settings.name ?? 'unknown',
        ...?attributes,
      },
      metrics: {'action_performed': 1},
    );
  }
}
