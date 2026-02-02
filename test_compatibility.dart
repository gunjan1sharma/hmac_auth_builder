import 'lib/hmac_operations.dart';

void main() {
  print('\n🔄 Cross-Platform Compatibility Test\n');
  print('=' * 60);

  // Test 1: Basic signature with fixed values
  print('\nTest 1: Fixed Timestamp & Nonce');
  print('-' * 60);

  final test1 = HmacOperations.generateSignature(
    {
      'property_id': 'PROP123',
      'aadhaar_number': '123456789012',
      'consent': true,
    },
    'ALT_TM_ADMINNLT65XER',
    config: const HmacConfig(
      customTimestamp: 1700000000000,
      customNonce: 'test-nonce-12345',
    ),
  );

  print('Timestamp: ${test1.timestamp}');
  print('Nonce: ${test1.nonce}');
  print('Canonical: ${test1.canonicalString}');
  print('Signature: ${test1.signature}');
  print('\n✓ Copy these values and verify with Node.js!');

  // Test 2: Multiple algorithms
  print('\n\nTest 2: Different Hash Algorithms');
  print('-' * 60);

  final algorithms = ['sha256', 'sha512', 'sha384'];
  final testPayload = {'test': 'data'};
  const testSecret = 'secret-key';

  for (final algo in algorithms) {
    final result = HmacOperations.generateSignature(
      testPayload,
      testSecret,
      config: HmacConfig(
        hashAlgorithm: algo,
        customTimestamp: 1700000000000,
        customNonce: 'test-nonce',
      ),
    );
    print('$algo: ${result.signature.substring(0, 40)}...');
  }

  // Test 3: Encodings
  print('\n\nTest 3: Different Encodings');
  print('-' * 60);

  final encodings = ['hex', 'base64', 'base64url'];

  for (final encoding in encodings) {
    final result = HmacOperations.generateSignature(
      testPayload,
      testSecret,
      config: HmacConfig(
        encoding: encoding,
        customTimestamp: 1700000000000,
        customNonce: 'test-nonce',
      ),
    );
    print('$encoding: ${result.signature.substring(0, 40)}...');
  }

  // Test 4: Verification
  print('\n\nTest 4: Signature Verification');
  print('-' * 60);

  final generated = HmacOperations.generateSignature(
    {'user_id': '123'},
    'secret',
  );

  final verification = HmacOperations.verifySignature(
    {'user_id': '123'},
    'secret',
    generated.signature,
    generated.timestamp,
    generated.nonce,
  );

  print('Generated: ${generated.signature.substring(0, 40)}...');
  print('Verification: ${verification.valid ? "✅ VALID" : "❌ INVALID"}');

  print('\n' + '=' * 60);
  print('✅ All tests completed!\n');
}
