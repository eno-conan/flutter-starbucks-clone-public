/// 注文検証結果を表すsealed class
///
/// サービス層からUI層へ検証結果を返すために使用します。
/// Sealed classを使用することで、パターンマッチングによる
/// 処理漏れをコンパイル時に検出できます。
sealed class OrderValidationResult {
  const OrderValidationResult();
}

/// 検証成功 - 注文処理を続行可能
class ValidationSuccess extends OrderValidationResult {
  const ValidationSuccess();
}

/// 店舗が閉店時間間近（閉店15分前以降）
///
/// この状態では注文処理を中断し、ユーザーに閉店ダイアログを表示します。
class StoreClosingSoon extends OrderValidationResult {
  const StoreClosingSoon({
    required this.closingTime,
    required this.minutesUntilClosing,
  });

  /// 閉店時刻（"HH:mm"形式）
  final String closingTime;

  /// 閉店までの残り時間（分）
  final int minutesUntilClosing;
}

/// 検証エラー
///
/// 店舗情報の取得失敗やネットワークエラーなど、
/// 注文処理を続行できないエラーが発生した場合に使用します。
class ValidationError extends OrderValidationResult {
  const ValidationError({
    required this.errorType,
    required this.message,
    this.exception,
  });

  /// エラー種別
  final ValidationErrorType errorType;

  /// エラーメッセージ
  final String message;

  /// 発生した例外（オプション）
  final Exception? exception;
}

/// 検証エラーの種別
enum ValidationErrorType {
  /// 店舗情報が見つからない
  storeNotFound,

  /// ネットワークエラー
  networkError,

  /// 残高不足
  insufficientBalance,

  /// カートが空
  cartEmpty,

  /// 不明なエラー
  unknown,
}
