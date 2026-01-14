// test/utils/sanitization_utils_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:testingapp/utils/sanitization_utils.dart';

void main() {
  group('SanitizationUtils', () {
    group('escapeHtml', () {
      test('should escape HTML special characters', () {
        expect(SanitizationUtils.escapeHtml('<script>'), '&lt;script&gt;');
        expect(SanitizationUtils.escapeHtml('Test & Company'), 'Test &amp; Company');
        expect(SanitizationUtils.escapeHtml('"quoted"'), '&quot;quoted&quot;');
        expect(SanitizationUtils.escapeHtml("'apostrophe'"), '&#x27;apostrophe&#x27;');
        expect(SanitizationUtils.escapeHtml('path/to/file'), 'path&#x2F;to&#x2F;file');
      });

      test('should return empty string for empty input', () {
        expect(SanitizationUtils.escapeHtml(''), '');
      });

      test('should not modify safe strings', () {
        expect(SanitizationUtils.escapeHtml('abc123'), 'abc123');
        expect(SanitizationUtils.escapeHtml('token-value_123'), 'token-value_123');
      });
    });

    group('sanitizeToken', () {
      test('should sanitize and escape token with suspicious content', () {
        final result = SanitizationUtils.sanitizeToken('<script>alert("xss")</script>token');
        expect(result, '&lt;script&gt;alert(&quot;xss&quot;)&lt;&#x2F;script&gt;token');
      });

      test('should remove control characters from token', () {
        final result = SanitizationUtils.sanitizeToken('token\x00\x1F\x7F');
        expect(result, 'token');
      });

      test('should trim whitespace from token', () {
        final result = SanitizationUtils.sanitizeToken('  token  ');
        expect(result, 'token');
      });

      test('should handle empty token', () {
        expect(SanitizationUtils.sanitizeToken(''), '');
      });

      test('should not modify valid tokens', () {
        const validToken = 'abc123-_XYZ';
        expect(SanitizationUtils.sanitizeToken(validToken), validToken);
      });

      test('should handle newlines and carriage returns', () {
        final result = SanitizationUtils.sanitizeToken('token\n\r');
        expect(result, 'token');
      });
    });

    group('sanitizeQueryParameter', () {
      test('should escape HTML and remove dangerous patterns', () {
        final result = SanitizationUtils.sanitizeQueryParameter('<script>alert("xss")</script>');
        expect(result, '');
      });

      test('should remove javascript: scheme', () {
        final result = SanitizationUtils.sanitizeQueryParameter('javascript:alert(1)');
        expect(result, 'alert(1)');
      });

      test('should remove event handlers', () {
        final result = SanitizationUtils.sanitizeQueryParameter('onload=alert(1)');
        expect(result, 'alert(1)');
      });

      test('should remove data: schemes', () {
        final result = SanitizationUtils.sanitizeQueryParameter('data:text/html,<h1>test</h1>');
        expect(result, 'text&#x2F;html,&lt;h1&gt;test&lt;&#x2F;h1&gt;');
      });

      test('should handle case insensitive patterns', () {
        final result = SanitizationUtils.sanitizeQueryParameter('ONCLICK=alert(1)');
        expect(result, 'alert(1)');
      });

      test('should not modify safe parameters', () {
        const safeParam = 'valid-parameter_123';
        expect(SanitizationUtils.sanitizeQueryParameter(safeParam), safeParam);
      });

      test('should handle empty parameter', () {
        expect(SanitizationUtils.sanitizeQueryParameter(''), '');
      });

      test('should handle tab parameter values', () {
        expect(SanitizationUtils.sanitizeQueryParameter('0'), '0');
        expect(SanitizationUtils.sanitizeQueryParameter('1'), '1');
        expect(SanitizationUtils.sanitizeQueryParameter('abc'), 'abc');
      });
    });

    group('XSS attack vectors', () {
      test('should defend against common XSS payloads', () {
        final xssPayloads = [
          '<svg onload=alert(1)>',
          '<img src=x onerror=alert(1)>',
          '<iframe src="javascript:alert(1)"></iframe>',
          'javascript:/*--></title></style></textarea></script></xmp><svg/onload=\'+/"/+/onmouseover=1/+/[*/[]/+alert(1)//\'>',
          '<script>alert(String.fromCharCode(88,83,83))</script>',
        ];

        for (final payload in xssPayloads) {
          final result = SanitizationUtils.sanitizeQueryParameter(payload);
          // Should not contain script tags or event handlers
          expect(result.toLowerCase(), isNot(contains('<script')));
          expect(result.toLowerCase(), isNot(contains('onload')));
          expect(result.toLowerCase(), isNot(contains('onerror')));
          expect(result.toLowerCase(), isNot(contains('javascript:')));
        }
      });
    });

    group('Edge cases', () {
      test('should handle very long strings', () {
        final longString = 'a' * 10000 + '<script>alert(1)</script>';
        final result = SanitizationUtils.sanitizeQueryParameter(longString);
        expect(result.length, greaterThan(0));
        expect(result, isNot(contains('<script>')));
      });

      test('should handle unicode characters', () {
        final unicodeString = 'ăêûũñç<script>alert(1)</script>';
        final result = SanitizationUtils.sanitizeQueryParameter(unicodeString);
        expect(result, contains('ăêûũñç'));
        expect(result, isNot(contains('<script>')));
      });

      test('should handle mixed content', () {
        final mixedString = 'valid-token<svg onload=alert(1)>more-valid-content';
        final result = SanitizationUtils.sanitizeQueryParameter(mixedString);
        expect(result, contains('valid-token'));
        expect(result, contains('more-valid-content'));
        expect(result, isNot(contains('onload')));
      });
    });
  });
}
