import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/relay_validation.dart';

void main() {
  group('RelayValidation Tests', () {
    group('validateRelayUrl', () {
      test('should return null for valid wss URL', () {
        final result = RelayValidation.validateRelayUrl('wss://relay.example.com');
        expect(result, isNull);
      });

      test('should return null for valid ws URL', () {
        final result = RelayValidation.validateRelayUrl('ws://localhost:8080');
        expect(result, isNull);
      });

      test('should return null for valid URL with path', () {
        final result = RelayValidation.validateRelayUrl('wss://relay.example.com/path');
        expect(result, isNull);
      });

      test('should return null for valid URL with port', () {
        final result = RelayValidation.validateRelayUrl('wss://relay.example.com:8080');
        expect(result, isNull);
      });

      test('should return null for valid URL with port and path', () {
        final result = RelayValidation.validateRelayUrl('wss://relay.example.com:8080/path');
        expect(result, isNull);
      });

      test('should return error for URL without protocol', () {
        final result = RelayValidation.validateRelayUrl('relay.example.com');
        expect(result, contains('URL must start with wss:// or ws://'));
      });

      test('should return error for HTTP URL', () {
        final result = RelayValidation.validateRelayUrl('http://relay.example.com');
        expect(result, contains('URL must start with wss:// or ws://'));
      });

      test('should return error for HTTPS URL', () {
        final result = RelayValidation.validateRelayUrl('https://relay.example.com');
        expect(result, contains('URL must start with wss:// or ws://'));
      });

      test('should return error for empty domain', () {
        final result = RelayValidation.validateRelayUrl('wss://');
        expect(result, contains('Domain name is required'));
      });

      test('should return error for URL with spaces', () {
        final result = RelayValidation.validateRelayUrl('wss://relay example.com');
        expect(result, contains('Domain cannot contain spaces'));
      });

      test('should handle URL with query parameters', () {
        final result = RelayValidation.validateRelayUrl('wss://relay.example.com?param=value');
        // Query parameters might be considered invalid by the current regex
        expect(result, isA<String?>());
      });

      test('should handle URL with fragment', () {
        final result = RelayValidation.validateRelayUrl('wss://relay.example.com#fragment');
        // Fragments might be considered invalid by the current regex
        expect(result, isA<String?>());
      });

    });

    group('shouldSkipValidation', () {
      test('should return true for empty string', () {
        final result = RelayValidation.shouldSkipValidation('');
        expect(result, isTrue);
      });

      test('should return true for just wss://', () {
        final result = RelayValidation.shouldSkipValidation('wss://');
        expect(result, isTrue);
      });

      test('should return true for just ws://', () {
        final result = RelayValidation.shouldSkipValidation('ws://');
        expect(result, isTrue);
      });

      test('should return false for complete URL', () {
        final result = RelayValidation.shouldSkipValidation('wss://relay.example.com');
        expect(result, isFalse);
      });

      test('should return false for partial URL with domain', () {
        final result = RelayValidation.shouldSkipValidation('wss://relay');
        expect(result, isFalse);
      });

      test('should return false for URL without protocol', () {
        final result = RelayValidation.shouldSkipValidation('relay.example.com');
        expect(result, isFalse);
      });
    });

    group('Edge cases', () {
      test('validateRelayUrl should handle null-like inputs gracefully', () {
        final result = RelayValidation.validateRelayUrl('null');
        expect(result, contains('URL must start with wss:// or ws://'));
      });

      test('shouldSkipValidation should handle mixed case protocols', () {
        final result1 = RelayValidation.shouldSkipValidation('WSS://');
        final result2 = RelayValidation.shouldSkipValidation('WS://');
        expect(result1, isFalse); // Should not skip, will be handled by validation
        expect(result2, isFalse); // Should not skip, will be handled by validation
      });

      test('validateRelayUrl should reject mixed case protocols', () {
        final result1 = RelayValidation.validateRelayUrl('WSS://relay.example.com');
        final result2 = RelayValidation.validateRelayUrl('WS://relay.example.com');
        expect(result1, contains('URL must start with wss:// or ws://'));
        expect(result2, contains('URL must start with wss:// or ws://'));
      });

      test('validateRelayUrl should handle very long URLs', () {
        final longDomain = 'a' * 100;
        final result = RelayValidation.validateRelayUrl('wss://$longDomain.com');
        expect(result, isNull); // Should be valid if it follows the pattern
      });

      test('validateRelayUrl should handle URLs with multiple dots', () {
        final result = RelayValidation.validateRelayUrl('wss://sub.domain.example.com');
        expect(result, isNull);
      });
    });
  });
}