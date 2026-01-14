// lib/utils/sanitization_utils.dart
import 'dart:convert';

/// HTMLエスケープとサニタイゼーション関連のユーティリティクラス
class SanitizationUtils {
  // プライベートコンストラクタ（インスタンス化を防ぐ）
  SanitizationUtils._();

  /// HTMLエスケープを実行してXSS攻撃を防止
  ///
  /// 以下の文字をエスケープします:
  /// - < → &lt;
  /// - > → &gt;
  /// - & → &amp;
  /// - " → &quot;
  /// - ' → &#x27;
  /// - / → &#x2F;
  static String escapeHtml(String input) {
    if (input.isEmpty) {
      return input;
    }

    return const HtmlEscape().convert(input);
  }

  /// ディープリンクのトークンをサニタイズ
  ///
  /// - HTMLエスケープを実行
  /// - 制御文字の除去
  /// - 改行文字の除去
  static String sanitizeToken(String token) {
    if (token.isEmpty) {
      return token;
    }

    // HTMLエスケープを実行
    String sanitized = escapeHtml(token);

    // 制御文字（\x00-\x1F）と改行文字を除去
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    // 先頭と末尾の空白を削除
    sanitized = sanitized.trim();

    return sanitized;
  }

  /// クエリパラメータの値をサニタイズ
  ///
  /// ディープリンクから取得したクエリパラメータの値を安全に処理
  static String sanitizeQueryParameter(String parameter) {
    if (parameter.isEmpty) {
      return parameter;
    }

    // HTMLエスケープを実行
    String sanitized = escapeHtml(parameter);

    // 危険な文字列パターンを除去
    // スクリプトタグ、イベントハンドラーなどを除去
    sanitized = _removeDangerousPatterns(sanitized);

    return sanitized;
  }

  /// 危険なHTMLパターンを除去
  static String _removeDangerousPatterns(String input) {
    // 大文字小文字を区別せずに危険なパターンをチェック
    String sanitized = input;

    // スクリプトタグ関連
    sanitized = sanitized.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      '',
    );
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');

    // イベントハンドラー
    sanitized = sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');

    // data: URL スキーム
    sanitized = sanitized.replaceAll(RegExp(r'data:', caseSensitive: false), '');

    return sanitized;
  }
}
