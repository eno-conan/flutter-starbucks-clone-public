import 'package:flutter_test/flutter_test.dart';
import 'package:testingapp/utils/sanitization_utils.dart';

void main() {
  group('SanitizationUtils', () {
    group('escapeHtml', () {
      test('空文字の場合は空文字を返すこと', () {
        expect(SanitizationUtils.escapeHtml(''), '');
      });

      test('HTML特殊文字がすべてエスケープされること', () {
        const input = '<script>alert("XSS")</script>&\'/';

        final result = SanitizationUtils.escapeHtml(input);

        expect(result, contains('&lt;'));
        expect(result, contains('&gt;'));
        expect(result, contains('&amp;'));
        expect(result, contains('&quot;'));
        // 実際の dart:convert HtmlEscape の変換結果は ' → &#39;, / → &#47;
        // (lib/utils/sanitization_utils.dartのdocコメントが &#x27;/&#x2F; と記載しているのは誤り)
        expect(result, contains('&#39;'));
        expect(result, contains('&#47;'));
        expect(result, isNot(contains('<script>')));
      });

      test('特殊文字を含まない文字列はそのまま返されること', () {
        const input = 'こんにちは Starbucks 123';

        final result = SanitizationUtils.escapeHtml(input);

        expect(result, input);
      });
    });

    group('sanitizeToken', () {
      test('空文字の場合は空文字を返すこと', () {
        expect(SanitizationUtils.sanitizeToken(''), '');
      });

      test('制御文字が除去されること', () {
        const input = 'valid-token\x00\x1F\x7F';

        final result = SanitizationUtils.sanitizeToken(input);

        expect(result, 'valid-token');
      });

      test('改行文字が除去されること', () {
        const input = 'line1\nline2\rline3';

        final result = SanitizationUtils.sanitizeToken(input);

        expect(result, 'line1line2line3');
      });

      test('先頭と末尾の空白が削除されること', () {
        const input = '  token-value  ';

        final result = SanitizationUtils.sanitizeToken(input);

        expect(result, 'token-value');
      });

      test('HTMLエスケープが適用されること', () {
        const input = '<b>token</b>';

        final result = SanitizationUtils.sanitizeToken(input);

        expect(result, isNot(contains('<b>')));
        expect(result, contains('&lt;b&gt;'));
      });
    });

    group('sanitizeQueryParameter', () {
      test('空文字の場合は空文字を返すこと', () {
        expect(SanitizationUtils.sanitizeQueryParameter(''), '');
      });

      test('scriptタグがそのままの形で残らないこと(HTMLエスケープにより無害化される)', () {
        const input = '<script>alert(1)</script>value';

        final result = SanitizationUtils.sanitizeQueryParameter(input);

        expect(result, isNot(contains('<script>')));
        expect(result, contains('value'));
      });

      test('javascript:スキームが除去されること', () {
        const input = 'javascript:alert(1)';

        final result = SanitizationUtils.sanitizeQueryParameter(input);

        expect(result, isNot(contains('javascript:')));
      });

      test('イベントハンドラーが除去されること', () {
        const input = 'onclick=alert(1)';

        final result = SanitizationUtils.sanitizeQueryParameter(input);

        expect(result, isNot(contains('onclick=')));
      });

      test('data:URLスキームが除去されること', () {
        const input = 'data:text/html,<script>alert(1)</script>';

        final result = SanitizationUtils.sanitizeQueryParameter(input);

        expect(result, isNot(contains('data:')));
      });

      test('危険なパターンを含まない通常の値はそのまま(エスケープ済みで)返されること', () {
        const input = 'tab=1';

        final result = SanitizationUtils.sanitizeQueryParameter(input);

        expect(result, 'tab=1');
      });
    });
  });
}
