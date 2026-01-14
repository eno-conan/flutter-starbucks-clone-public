import 'package:intl/intl.dart';

/// タイムゾーン変換のユーティリティクラス
/// UTCで保存された時刻を端末のローカルタイムゾーンで表示するために使用
class TimezoneUtil {
  /// UTC時刻をローカルタイムゾーンに変換してフォーマットする
  ///
  /// [utcDateTime] UTC時刻として保存されたDateTime
  /// [format] フォーマット形式（デフォルト: 'yyyy/M/d H:mm'）
  ///
  /// 例:
  /// UTC 2024/1/1 08:54 -> JST 2024/1/1 17:54 (Asia/Tokyo)
  /// UTC 2024/1/1 08:54 -> PST 2024/1/1 00:54 (America/Los_Angeles)
  static String formatLocalTime(DateTime utcDateTime, {String format = 'yyyy/M/d H:mm'}) {
    // UTC時刻をローカル時刻に変換
    final localDateTime = utcDateTime.toLocal();

    // 指定されたフォーマットで整形
    final formatter = DateFormat(format);
    return formatter.format(localDateTime);
  }

  /// UTC時刻をローカル時刻に変換（DateTime形式で返却）
  ///
  /// [utcDateTime] UTC時刻として保存されたDateTime
  static DateTime toLocalTime(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }
}
