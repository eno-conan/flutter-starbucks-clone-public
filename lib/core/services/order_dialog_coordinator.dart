import 'package:flutter/material.dart';

import '../../screens/starbucks_user_side/mobile_order_pay/tab_histories/service_status_dialogs.dart';
import '../../shared/widgets/dialogs/error_dialog.dart';
import '../models/order_validation_result.dart';

/// ダイアログ表示を一元管理するクラス
///
/// 検証結果に基づいて適切なダイアログを表示します。
/// すべてのダイアログ表示ロジックをこのクラスに集約することで、
/// ダイアログ表示の一貫性を保ち、保守性を向上させます。
class OrderDialogCoordinator {
  /// 検証結果に基づいてダイアログを表示
  ///
  /// Sealed classのパターンマッチングにより、
  /// すべてのケースを処理することを強制します。
  ///
  /// パラメータ:
  /// - [context]: BuildContext
  /// - [result]: 検証結果
  ///
  /// 戻り値:
  /// - true: ユーザーが処理を続行できる
  /// - false: 処理を中断する必要がある
  static bool showValidationResultDialog(
    BuildContext context,
    OrderValidationResult result,
  ) {
    return switch (result) {
      ValidationSuccess() => true,
      StoreClosingSoon() => _showStoreClosingDialog(context),
      ValidationError() => _showValidationErrorDialog(context, result),
    };
  }

  /// 閉店時間間近ダイアログを表示
  ///
  /// 店舗が閉店15分前以降の場合に表示されます。
  /// ユーザーに注文を中断させます。
  static bool _showStoreClosingDialog(BuildContext context) {
    showCurrentlyClosedDialog(context);
    return false; // 処理を中断
  }

  /// 検証エラーダイアログを表示
  ///
  /// 店舗情報の取得失敗やネットワークエラーなど、
  /// 検証中に発生したエラーを表示します。
  static bool _showValidationErrorDialog(
    BuildContext context,
    ValidationError error,
  ) {
    final message = _getErrorMessage(error);
    showErrorDialog(context, message);
    return false; // 処理を中断
  }

  /// エラー種別に応じたエラーメッセージを取得
  ///
  /// Switch式を使用することで、すべてのエラータイプに対する
  /// メッセージ定義を強制します。
  static String _getErrorMessage(ValidationError error) {
    return switch (error.errorType) {
      ValidationErrorType.storeNotFound => '店舗情報が見つかりませんでした',
      ValidationErrorType.networkError =>
        'ネットワークエラーが発生しました\n時間をおいて再度お試しください',
      ValidationErrorType.insufficientBalance => '残高が不足しています',
      ValidationErrorType.cartEmpty => 'カートに商品が入っていません',
      ValidationErrorType.unknown => '予期しないエラーが発生しました\n${error.message}',
    };
  }

  /// 決済エラーダイアログを表示
  ///
  /// 決済処理中に発生したエラーを表示します。
  /// Phase 2のProvider統合時に使用されます。
  static void showSettlementError(BuildContext context, String message) {
    showErrorDialog(context, '決済処理中にエラーが発生しました\n$message');
  }
}
