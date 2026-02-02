import 'package:hmac_auth_builder/hmac_operations.dart';

void main() {
  print('🔐 HMAC Auth Builder - Dart/Flutter Example\n');

  // Example 1: Basic signature generation
  print('Example 1: Basic Signature Generation');
  print('=' * 50);

  final payload = {
    'transaction_id': 'TXN-2026-001',
    'amount': 5000,
    'currency': 'USD',
  };

  final result = HmacOperations.generateSignature(payload, 'your-secret-key');

  print('Timestamp: ${result.timestamp}');
  print('Nonce: ${result.nonce}');
  print('Signature: ${result.signature}');
  print('Algorithm: ${result.algorithm}');
  print('Canonical String: ${result.canonicalString}');
  print('');

  // Example 2: Signature verification
  print('Example 2: Signature Verification');
  print('=' * 50);

  final verification = HmacOperations.verifySignature(
    payload,
    'your-secret-key',
    result.signature,
    result.timestamp,
    result.nonce,
  );

  print('Valid: ${verification.valid}');
  print('Timestamp Age: ${verification.timestampAge}ms');
  print('');

  // Example 3: Custom configuration
  print('Example 3: Custom Configuration');
  print('=' * 50);

  final customResult = HmacOperations.generateSignature(
    payload,
    'your-secret-key',
    config: const HmacConfig(
      hashAlgorithm: 'sha512',
      encoding: 'base64',
      canonicalFields: ['transaction_id', 'amount', 'currency'],
    ),
  );

  print('SHA-512 Signature: ${customResult.signature}');
  print('');

  // Example 4: Cross-platform test (compatible with Node.js)
  print('Example 4: Cross-Platform Compatibility Test');
  print('=' * 50);

  final testPayload = {
    'property_id': 'PROP123',
    'aadhaar_number': '123456789012',
    'consent': true,
  };

  final crossPlatformResult = HmacOperations.generateSignature(
    testPayload,
    'ALT_TM_ADMINNLT65XER',
    config: const HmacConfig(
      customTimestamp: 1700000000000,
      customNonce: 'test-nonce-12345',
    ),
  );

  print('Signature: ${crossPlatformResult.signature}');
  print('Canonical: ${crossPlatformResult.canonicalString}');
  print('');
  print('✅ This signature should match Node.js output with same inputs!');
}
