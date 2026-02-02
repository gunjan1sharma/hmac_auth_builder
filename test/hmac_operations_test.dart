import 'package:test/test.dart';
import '../lib/hmac_operations.dart';

void main() {
  group('HmacOperations', () {
    final testPayload = {'property_id': 'PROP123', 'user_id': '456'};
    const testSecret = 'test-secret-key-12345';

    group('generateSignature', () {
      test('should generate signature with default config', () {
        final result = HmacOperations.generateSignature(
          testPayload,
          testSecret,
        );

        expect(result.signature, isNotEmpty);
        expect(result.timestamp, isNotNull);
        expect(result.nonce, isNotEmpty);
        expect(result.algorithm, equals('sha256'));
        expect(result.encoding, equals('hex'));
      });

      test('should generate deterministic signature with fixed values', () {
        final config = HmacConfig(
          customTimestamp: 1700000000000,
          customNonce: 'test-nonce-12345',
        );

        final result1 = HmacOperations.generateSignature(
          testPayload,
          testSecret,
          config: config,
        );

        final result2 = HmacOperations.generateSignature(
          testPayload,
          testSecret,
          config: config,
        );

        expect(result1.signature, equals(result2.signature));
        expect(result1.timestamp, equals(result2.timestamp));
        expect(result1.nonce, equals(result2.nonce));
      });

      test('should support different hash algorithms', () {
        final algorithms = ['sha256', 'sha512', 'sha384'];

        for (final algo in algorithms) {
          final result = HmacOperations.generateSignature(
            testPayload,
            testSecret,
            config: HmacConfig(hashAlgorithm: algo),
          );

          expect(result.algorithm, equals(algo));
          expect(result.signature, isNotEmpty);
        }
      });

      test('should support different encodings', () {
        final encodings = ['hex', 'base64', 'base64url'];

        for (final encoding in encodings) {
          final result = HmacOperations.generateSignature(
            testPayload,
            testSecret,
            config: HmacConfig(encoding: encoding),
          );

          expect(result.encoding, equals(encoding));
          expect(result.signature, isNotEmpty);
        }
      });

      test('should throw error for empty payload', () {
        expect(
          () => HmacOperations.generateSignature({}, testSecret),
          throwsArgumentError,
        );
      });

      test('should throw error for short secret key', () {
        expect(
          () => HmacOperations.generateSignature(testPayload, 'short'),
          throwsArgumentError,
        );
      });

      test('should support custom canonical fields', () {
        final result = HmacOperations.generateSignature(
          testPayload,
          testSecret,
          config: HmacConfig(canonicalFields: ['property_id', 'user_id']),
        );

        expect(result.canonicalString, isNotEmpty);
        expect(result.canonicalString, contains('PROP123'));
        expect(result.canonicalString, contains('456'));
      });

      test('should support JSON signature method', () {
        final result = HmacOperations.generateSignature(
          testPayload,
          testSecret,
          config: const HmacConfig(signatureMethod: 'json'),
        );

        expect(result.signature, isNotEmpty);
        expect(result.canonicalString, contains('property_id'));
      });

      test('should handle boolean values correctly', () {
        final payload = {'enabled': true, 'disabled': false};

        final result = HmacOperations.generateSignature(payload, testSecret);

        expect(result.canonicalString, contains('1')); // true -> '1'
        expect(result.canonicalString, contains('0')); // false -> '0'
      });

      test('should handle null values correctly', () {
        final payload = {'field1': 'value', 'field2': null};

        final result = HmacOperations.generateSignature(payload, testSecret);

        expect(result.signature, isNotEmpty);
      });
    });

    group('verifySignature', () {
      test('should verify valid signature', () {
        final generated = HmacOperations.generateSignature(
          testPayload,
          testSecret,
        );

        final verification = HmacOperations.verifySignature(
          testPayload,
          testSecret,
          generated.signature,
          generated.timestamp,
          generated.nonce,
        );

        expect(verification.valid, isTrue);
        expect(verification.error, isNull);
      });

      test('should reject tampered payload', () {
        final generated = HmacOperations.generateSignature(
          testPayload,
          testSecret,
        );

        final tamperedPayload = {
          ...testPayload,
          'user_id': '999', // Changed
        };

        final verification = HmacOperations.verifySignature(
          tamperedPayload,
          testSecret,
          generated.signature,
          generated.timestamp,
          generated.nonce,
        );

        expect(verification.valid, isFalse);
        expect(verification.error, equals('Signature mismatch'));
      });

      test('should reject expired timestamp', () {
        final oldTimestamp =
            DateTime.now().millisecondsSinceEpoch - 300000; // 5 min ago

        final generated = HmacOperations.generateSignature(
          testPayload,
          testSecret,
          config: HmacConfig(customTimestamp: oldTimestamp),
        );

        final verification = HmacOperations.verifySignature(
          testPayload,
          testSecret,
          generated.signature,
          oldTimestamp,
          generated.nonce,
          config: const VerificationConfig(
            timestampTolerance: 60000, // 1 minute
          ),
        );

        expect(verification.valid, isFalse);
        expect(verification.error, contains('Timestamp expired'));
      });

      test('should handle verification with matching config', () {
        final config = const HmacConfig(
          hashAlgorithm: 'sha512',
          encoding: 'base64',
        );

        final generated = HmacOperations.generateSignature(
          testPayload,
          testSecret,
          config: config,
        );

        final verification = HmacOperations.verifySignature(
          testPayload,
          testSecret,
          generated.signature,
          generated.timestamp,
          generated.nonce,
          config: VerificationConfig(
            hashAlgorithm: config.hashAlgorithm,
            encoding: config.encoding,
          ),
        );

        expect(verification.valid, isTrue);
      });
    });

    group('Cross-platform compatibility', () {
      test('should generate signature compatible with Node.js', () {
        // Fixed values for deterministic test
        final payload = {
          'property_id': 'PROP123',
          'aadhaar_number': '123456789012',
          'consent': true,
        };
        const secret = 'ALT_TM_ADMINNLT65XER';
        const timestamp = 1700000000000;
        const nonce = 'test-nonce-12345';

        final result = HmacOperations.generateSignature(
          payload,
          secret,
          config: const HmacConfig(
            customTimestamp: timestamp,
            customNonce: nonce,
          ),
        );

        // Print for manual verification with Node.js
        print('Dart Signature: ${result.signature}');
        print('Dart Canonical: ${result.canonicalString}');
        print('Dart Timestamp: ${result.timestamp}');
        print('Dart Nonce: ${result.nonce}');

        // Expected canonical string format:
        // timestamp|nonce|aadhaar_number|consent|property_id (alphabetically sorted)
        expect(
          result.canonicalString,
          equals('1700000000000|test-nonce-12345|123456789012|1|PROP123'),
        );
      });
    });
  });
}
