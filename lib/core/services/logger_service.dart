import 'package:logger/logger.dart';

/// アプリ全体で使用するロガーサービス
class LoggerService {
  static final Logger _logger = Logger(printer: PrettyPrinter(printTime: true));

  /// 情報レベルのログ出力
  static void info(String message, [dynamic error]) {
    _logger.i(message, error: error);
  }

  /// 警告レベルのログ出力
  static void warn(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// エラーレベルのログ出力
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// デバッグレベルのログ出力
  static void debug(String message, [dynamic error]) {
    _logger.d(message, error: error);
  }

  /// トレースレベルのログ出力
  static void trace(String message, [dynamic error]) {
    _logger.t(message, error: error);
  }

  /// 致命的エラーレベルのログ出力
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
