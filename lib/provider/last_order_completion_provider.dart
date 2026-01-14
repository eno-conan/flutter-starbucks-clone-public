import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 最後の注文完了時刻を管理するNotifier
///
/// 注文完了直後にニックネームダイアログが表示されないよう、
/// 注文完了時刻を記録し、一定時間内はダイアログ表示を抑制するために使用します。
class LastOrderCompletionNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    return null;
  }

  /// 注文完了時刻を記録
  void markOrderCompleted() {
    state = DateTime.now();
  }

  /// 最後の注文完了から指定秒数経過したかチェック
  ///
  /// [seconds] - 経過を確認する秒数（デフォルト: 60秒）
  /// 戻り値: 指定秒数経過している、または注文完了記録がない場合はtrue
  bool hasElapsedSince({int seconds = 60}) {
    if (state == null) {
      return true; // 注文完了記録がない場合は常にtrue
    }
    final elapsed = DateTime.now().difference(state!);
    return elapsed.inSeconds >= seconds;
  }

  /// 注文完了時刻をクリア
  void clear() {
    state = null;
  }
}

/// 最後の注文完了時刻を管理するProvider
final lastOrderCompletionProvider = NotifierProvider<LastOrderCompletionNotifier, DateTime?>(
  LastOrderCompletionNotifier.new,
);
