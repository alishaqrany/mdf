import 'package:flutter_test/flutter_test.dart';

import 'package:mdf_app/core/security/security_utils.dart';

void main() {
  group('SecurityUtils', () {
    // ─────────────────────────────────────
    // enforceHttps
    // ─────────────────────────────────────
    group('enforceHttps', () {
      test('returns null for null input', () {
        expect(SecurityUtils.enforceHttps(null), isNull);
      });

      test('returns null for empty string', () {
        expect(SecurityUtils.enforceHttps(''), isNull);
        expect(SecurityUtils.enforceHttps('   '), isNull);
      });

      test('keeps https:// URLs unchanged', () {
        expect(
          SecurityUtils.enforceHttps('https://example.com'),
          'https://example.com',
        );
      });

      test('upgrades http:// to https://', () {
        expect(
          SecurityUtils.enforceHttps('http://example.com'),
          'https://example.com',
        );
      });

      test('prepends https:// when no scheme', () {
        expect(
          SecurityUtils.enforceHttps('example.com'),
          'https://example.com',
        );
      });

      test('trims whitespace', () {
        expect(
          SecurityUtils.enforceHttps('  https://example.com  '),
          'https://example.com',
        );
      });
    });

    // ─────────────────────────────────────
    // isSecureUrl
    // ─────────────────────────────────────
    group('isSecureUrl', () {
      test('returns true for HTTPS', () {
        expect(SecurityUtils.isSecureUrl('https://example.com'), isTrue);
      });

      test('returns false for HTTP', () {
        expect(SecurityUtils.isSecureUrl('http://example.com'), isFalse);
      });
    });

    // ─────────────────────────────────────
    // sanitizeInput
    // ─────────────────────────────────────
    group('sanitizeInput', () {
      test('removes HTML tags', () {
        expect(
          SecurityUtils.sanitizeInput('<b>Bold</b>'),
          'Bold',
        );
      });

      test('removes script-related patterns', () {
        expect(
          SecurityUtils.sanitizeInput('javascript:alert(1)'),
          'alert(1)',
        );
      });

      test('removes onerror attributes', () {
        expect(
          SecurityUtils.sanitizeInput('onerror:doSomething()'),
          'doSomething()',
        );
      });

      test('handles nested HTML tags', () {
        expect(
          SecurityUtils.sanitizeInput('<div><span>Test</span></div>'),
          'Test',
        );
      });

      test('preserves plain text', () {
        expect(
          SecurityUtils.sanitizeInput('Hello World'),
          'Hello World',
        );
      });

      test('trims result', () {
        expect(
          SecurityUtils.sanitizeInput('  test  '),
          'test',
        );
      });
    });

    // ─────────────────────────────────────
    // maskTokenInUrl
    // ─────────────────────────────────────
    group('maskTokenInUrl', () {
      test('masks token parameter', () {
        expect(
          SecurityUtils.maskTokenInUrl(
            'https://example.com/file?token=abc123&mode=download',
          ),
          'https://example.com/file?token=***&mode=download',
        );
      });

      test('masks wstoken parameter', () {
        expect(
          SecurityUtils.maskTokenInUrl(
            'https://example.com/api?wstoken=secret123',
          ),
          'https://example.com/api?wstoken=***',
        );
      });

      test('preserves URL without tokens', () {
        const url = 'https://example.com/page?id=1';
        expect(SecurityUtils.maskTokenInUrl(url), url);
      });
    });

    // ─────────────────────────────────────
    // isValidDomain
    // ─────────────────────────────────────
    group('isValidDomain', () {
      test('valid domain', () {
        expect(SecurityUtils.isValidDomain('example.com'), isTrue);
        expect(SecurityUtils.isValidDomain('moodle.university.edu'), isTrue);
      });

      test('invalid domain — no TLD', () {
        expect(SecurityUtils.isValidDomain('localhost'), isFalse);
      });

      test('invalid domain — starts with dash', () {
        expect(SecurityUtils.isValidDomain('-example.com'), isFalse);
      });
    });

    // ─────────────────────────────────────
    // isAllowedOrigin
    // ─────────────────────────────────────
    group('isAllowedOrigin', () {
      test('same host is allowed', () {
        expect(
          SecurityUtils.isAllowedOrigin(
            'https://moodle.example.com/page',
            'https://moodle.example.com',
          ),
          isTrue,
        );
      });

      test('subdomain of host is allowed', () {
        expect(
          SecurityUtils.isAllowedOrigin(
            'https://cdn.moodle.example.com/image.png',
            'https://moodle.example.com',
          ),
          isTrue,
        );
      });

      test('different host is rejected', () {
        expect(
          SecurityUtils.isAllowedOrigin(
            'https://evil.com/steal',
            'https://moodle.example.com',
          ),
          isFalse,
        );
      });

      test('handles invalid URLs gracefully', () {
        expect(
          SecurityUtils.isAllowedOrigin(
            'not a url',
            'also not a url',
          ),
          isFalse,
        );
      });
    });
  });
}
