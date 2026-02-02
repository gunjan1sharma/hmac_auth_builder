/// HmacOperations - Production-ready HMAC signature generation for API authentication
/// Dart/Flutter version with full type safety
///
/// Generates timestamp, nonce, and HMAC-SHA256 signatures for secure API requests.
/// Supports canonical string signing (default) and full JSON signing.
/// Cross-platform compatible with Node.js, PHP, Python, Java, etc.
///
/// Compatible with hmac-auth-builder npm package
library hmac_operations;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Configuration options for signature generation
class HmacConfig {
  /// Signature method: 'canonical' or 'json'
  final String signatureMethod;

  /// Separator for canonical string (default: '|')
  final String separator;

  /// Explicit field order for canonical signing
  final List<String>? canonicalFields;

  /// Hash algorithm: 'sha256', 'sha512', 'sha384', 'sha1', 'md5'
  final String hashAlgorithm;

  /// Output encoding: 'hex', 'base64', 'base64url'
  final String encoding;

  /// Timestamp format: 'milliseconds', 'seconds', 'unix', 'iso8601'
  final String timestampFormat;

  /// Nonce format: 'uuid-v4', 'uuid-v1', 'random-hex', 'random-base64', 'custom'
  final String nonceFormat;

  /// Custom nonce generator function
  final String Function()? customNonceGenerator;

  /// Custom timestamp (for testing)
  final dynamic customTimestamp;

  /// Custom nonce (for testing)
  final String? customNonce;

  /// Include timestamp in signature payload
  final bool includeTimestampInSignature;

  /// Include nonce in signature payload
  final bool includeNonceInSignature;

  /// Sort JSON keys when using 'json' method
  final bool sortJsonKeys;

  const HmacConfig({
    this.signatureMethod = 'canonical',
    this.separator = '|',
    this.canonicalFields,
    this.hashAlgorithm = 'sha256',
    this.encoding = 'hex',
    this.timestampFormat = 'milliseconds',
    this.nonceFormat = 'uuid-v4',
    this.customNonceGenerator,
    this.customTimestamp,
    this.customNonce,
    this.includeTimestampInSignature = true,
    this.includeNonceInSignature = true,
    this.sortJsonKeys = true,
  });

  HmacConfig copyWith({
    String? signatureMethod,
    String? separator,
    List<String>? canonicalFields,
    String? hashAlgorithm,
    String? encoding,
    String? timestampFormat,
    String? nonceFormat,
    String Function()? customNonceGenerator,
    dynamic customTimestamp,
    String? customNonce,
    bool? includeTimestampInSignature,
    bool? includeNonceInSignature,
    bool? sortJsonKeys,
  }) {
    return HmacConfig(
      signatureMethod: signatureMethod ?? this.signatureMethod,
      separator: separator ?? this.separator,
      canonicalFields: canonicalFields ?? this.canonicalFields,
      hashAlgorithm: hashAlgorithm ?? this.hashAlgorithm,
      encoding: encoding ?? this.encoding,
      timestampFormat: timestampFormat ?? this.timestampFormat,
      nonceFormat: nonceFormat ?? this.nonceFormat,
      customNonceGenerator: customNonceGenerator ?? this.customNonceGenerator,
      customTimestamp: customTimestamp ?? this.customTimestamp,
      customNonce: customNonce ?? this.customNonce,
      includeTimestampInSignature:
          includeTimestampInSignature ?? this.includeTimestampInSignature,
      includeNonceInSignature:
          includeNonceInSignature ?? this.includeNonceInSignature,
      sortJsonKeys: sortJsonKeys ?? this.sortJsonKeys,
    );
  }
}

/// Result object from signature generation
class SignatureResult {
  /// Generated timestamp
  final dynamic timestamp;

  /// Generated nonce
  final String nonce;

  /// HMAC signature
  final String signature;

  /// Hash algorithm used
  final String algorithm;

  /// Encoding format used
  final String encoding;

  /// The canonical string that was signed (for debugging)
  final String canonicalString;

  const SignatureResult({
    required this.timestamp,
    required this.nonce,
    required this.signature,
    required this.algorithm,
    required this.encoding,
    required this.canonicalString,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'nonce': nonce,
      'signature': signature,
      'algorithm': algorithm,
      'encoding': encoding,
      'canonicalString': canonicalString,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

/// Result from signature verification
class VerificationResult {
  /// Whether signature is valid
  final bool valid;

  /// Error message if invalid
  final String? error;

  /// Expected signature (for debugging)
  final String? expected;

  /// Received signature (for debugging)
  final String? received;

  /// Age of timestamp in milliseconds
  final int timestampAge;

  const VerificationResult({
    required this.valid,
    this.error,
    this.expected,
    this.received,
    required this.timestampAge,
  });

  Map<String, dynamic> toJson() {
    return {
      'valid': valid,
      if (error != null) 'error': error,
      if (expected != null) 'expected': expected,
      if (received != null) 'received': received,
      'timestampAge': timestampAge,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

/// Configuration for signature verification
class VerificationConfig extends HmacConfig {
  /// Allowed timestamp age in milliseconds (default: 180000 = 3 minutes)
  final int timestampTolerance;

  const VerificationConfig({
    super.signatureMethod,
    super.separator,
    super.canonicalFields,
    super.hashAlgorithm,
    super.encoding,
    super.timestampFormat,
    super.nonceFormat,
    super.customNonceGenerator,
    super.customTimestamp,
    super.customNonce,
    super.includeTimestampInSignature,
    super.includeNonceInSignature,
    super.sortJsonKeys,
    this.timestampTolerance = 180000, // 3 minutes default
  });
}

/// HmacOperations class for generating and verifying HMAC signatures
class HmacOperations {
  static const _uuid = Uuid();

  /// Generate HMAC signature with timestamp and nonce for API authentication
  ///
  /// [payload] - The JSON object to sign
  /// [secretKey] - The secret key for HMAC generation
  /// [config] - Optional configuration
  /// Returns Result object containing timestamp, nonce, and signature
  ///
  /// Example:
  /// ```dart
  /// final result = HmacOperations.generateSignature(
  ///   {'property_id': 'PROP123', 'user_id': '456'},
  ///   'your-secret-key'
  /// );
  /// print(result.signature);
  /// ```
  static SignatureResult generateSignature(
    Map<String, dynamic> payload,
    String secretKey, {
    HmacConfig config = const HmacConfig(),
  }) {
    try {
      // Step 1: Validate Inputs
      _validateInputs(payload, secretKey, config);

      // Step 2: Generate Timestamp
      final timestamp = _generateTimestamp(config);

      // Step 3: Generate Nonce
      final nonce = _generateNonce(config);

      // Step 4: Create Signature Payload
      final canonicalString = _createCanonicalString(
        payload,
        timestamp,
        nonce,
        config,
      );

      // Step 5: Generate HMAC Signature
      final signature = _generateHmac(canonicalString, secretKey, config);

      // Step 6: Return Result
      return SignatureResult(
        timestamp: timestamp,
        nonce: nonce,
        signature: signature,
        algorithm: config.hashAlgorithm,
        encoding: config.encoding,
        canonicalString: canonicalString,
      );
    } catch (e) {
      throw Exception(
        '[HmacOperations.generateSignature] Failed to generate signature: $e\n'
        'Context: ${jsonEncode({'payload': payload, 'configProvided': config})}',
      );
    }
  }

  /// Verify a signature against expected values
  ///
  /// [payload] - The original payload
  /// [secretKey] - The secret key
  /// [receivedSignature] - The signature to verify
  /// [receivedTimestamp] - The timestamp from request
  /// [receivedNonce] - The nonce from request
  /// [config] - Configuration (must match generation config)
  /// Returns Verification result
  ///
  /// Example:
  /// ```dart
  /// final verification = HmacOperations.verifySignature(
  ///   payload,
  ///   secretKey,
  ///   receivedSignature,
  ///   receivedTimestamp,
  ///   receivedNonce,
  /// );
  ///
  /// if (!verification.valid) {
  ///   print(verification.error);
  /// }
  /// ```
  static VerificationResult verifySignature(
    Map<String, dynamic> payload,
    String secretKey,
    String receivedSignature,
    dynamic receivedTimestamp,
    String receivedNonce, {
    VerificationConfig config = const VerificationConfig(),
  }) {
    try {
      // Generate expected signature with same config
      final expectedResult = generateSignature(
        payload,
        secretKey,
        config: config.copyWith(
          customTimestamp: receivedTimestamp,
          customNonce: receivedNonce,
        ),
      );

      // Check timestamp age
      int timestampAge = 0;

      if (receivedTimestamp is int ||
          (receivedTimestamp is String &&
              int.tryParse(receivedTimestamp) != null)) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final timestampNum = receivedTimestamp is int
            ? receivedTimestamp
            : int.parse(receivedTimestamp);
        final timestampMs = timestampNum > 9999999999
            ? timestampNum
            : timestampNum * 1000;
        timestampAge = (now - timestampMs).abs();

        if (timestampAge > config.timestampTolerance) {
          return VerificationResult(
            valid: false,
            error:
                'Timestamp expired. Age: ${timestampAge}ms, Tolerance: ${config.timestampTolerance}ms',
            timestampAge: timestampAge,
          );
        }
      }

      // Timing-safe comparison
      final signatureMatch = _timingSafeEqual(
        receivedSignature,
        expectedResult.signature,
      );

      if (!signatureMatch) {
        return VerificationResult(
          valid: false,
          error: 'Signature mismatch',
          expected: expectedResult.signature,
          received: receivedSignature,
          timestampAge: timestampAge,
        );
      }

      return VerificationResult(valid: true, timestampAge: timestampAge);
    } catch (e) {
      return VerificationResult(
        valid: false,
        error: 'Verification failed: $e',
        timestampAge: 0,
      );
    }
  }

  /// Validate all inputs with detailed error messages
  static void _validateInputs(
    Map<String, dynamic> payload,
    String secretKey,
    HmacConfig config,
  ) {
    // Validate payload
    if (payload.isEmpty) {
      throw ArgumentError('Payload cannot be an empty object');
    }

    // Validate secret key
    if (secretKey.isEmpty) {
      throw ArgumentError('Secret key must be a non-empty string');
    }

    if (secretKey.length < 8) {
      throw ArgumentError(
        'Secret key is too short (${secretKey.length} characters). '
        'Minimum 8 characters required for security.',
      );
    }

    // Validate signature method
    if (!['canonical', 'json'].contains(config.signatureMethod)) {
      throw ArgumentError(
        'Invalid signatureMethod: "${config.signatureMethod}". '
        "Must be 'canonical' or 'json'",
      );
    }

    // Validate hash algorithm
    if (![
      'sha256',
      'sha512',
      'sha1',
      'sha384',
      'md5',
    ].contains(config.hashAlgorithm)) {
      throw ArgumentError(
        'Invalid hashAlgorithm: "${config.hashAlgorithm}". '
        'Supported: sha256, sha512, sha384, sha1, md5',
      );
    }

    // Validate encoding
    if (!['hex', 'base64', 'base64url'].contains(config.encoding)) {
      throw ArgumentError(
        'Invalid encoding: "${config.encoding}". '
        'Supported: hex, base64, base64url',
      );
    }

    // Validate timestamp format
    if (![
      'milliseconds',
      'seconds',
      'unix',
      'iso8601',
    ].contains(config.timestampFormat)) {
      throw ArgumentError(
        'Invalid timestampFormat: "${config.timestampFormat}". '
        'Supported: milliseconds, seconds, unix, iso8601',
      );
    }

    // Validate nonce format
    if (![
      'uuid-v4',
      'uuid-v1',
      'random-hex',
      'random-base64',
      'custom',
    ].contains(config.nonceFormat)) {
      throw ArgumentError(
        'Invalid nonceFormat: "${config.nonceFormat}". '
        'Supported: uuid-v4, uuid-v1, random-hex, random-base64, custom',
      );
    }

    // Validate custom nonce generator
    if (config.nonceFormat == 'custom' && config.customNonceGenerator == null) {
      throw ArgumentError(
        'customNonceGenerator must be provided when nonceFormat is "custom"',
      );
    }

    // Validate canonical fields
    if (config.canonicalFields != null) {
      final payloadKeys = payload.keys.toList();
      final missingFields = config.canonicalFields!
          .where((f) => !payloadKeys.contains(f))
          .toList();
      if (missingFields.isNotEmpty) {
        throw ArgumentError(
          'canonicalFields contains fields not present in payload: ${missingFields.join(', ')}\n'
          'Available fields: ${payloadKeys.join(', ')}',
        );
      }
    }
  }

  /// Generate timestamp in specified format
  static dynamic _generateTimestamp(HmacConfig config) {
    try {
      if (config.customTimestamp != null) {
        return config.customTimestamp;
      }

      final now = DateTime.now();

      switch (config.timestampFormat) {
        case 'milliseconds':
          return now.millisecondsSinceEpoch;

        case 'seconds':
        case 'unix':
          return (now.millisecondsSinceEpoch / 1000).floor();

        case 'iso8601':
          return now.toUtc().toIso8601String();

        default:
          throw ArgumentError(
            'Unsupported timestampFormat: ${config.timestampFormat}',
          );
      }
    } catch (e) {
      throw Exception('[_generateTimestamp] Failed to generate timestamp: $e');
    }
  }

  /// Generate nonce in specified format
  static String _generateNonce(HmacConfig config) {
    try {
      if (config.customNonce != null) {
        return config.customNonce!;
      }

      switch (config.nonceFormat) {
        case 'uuid-v4':
          return _uuid.v4();

        case 'uuid-v1':
          return _uuid.v1();

        case 'random-hex':
          final random = Random.secure();
          final bytes = List<int>.generate(16, (_) => random.nextInt(256));
          return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

        case 'random-base64':
          final random = Random.secure();
          final bytes = List<int>.generate(16, (_) => random.nextInt(256));
          return base64.encode(bytes);

        case 'custom':
          if (config.customNonceGenerator == null) {
            throw ArgumentError(
              'customNonceGenerator function is required for custom nonce',
            );
          }
          final customNonce = config.customNonceGenerator!();
          if (customNonce.isEmpty) {
            throw ArgumentError(
              'customNonceGenerator must return a non-empty string',
            );
          }
          return customNonce;

        default:
          throw ArgumentError('Unsupported nonceFormat: ${config.nonceFormat}');
      }
    } catch (e) {
      throw Exception('[_generateNonce] Failed to generate nonce: $e');
    }
  }

  /// Create canonical string for signing
  static String _createCanonicalString(
    Map<String, dynamic> payload,
    dynamic timestamp,
    String nonce,
    HmacConfig config,
  ) {
    try {
      if (config.signatureMethod == 'json') {
        return _createJsonString(payload, timestamp, nonce, config);
      } else {
        return _createCanonicalFieldString(payload, timestamp, nonce, config);
      }
    } catch (e) {
      throw Exception(
        '[_createCanonicalString] Failed to create canonical string: $e',
      );
    }
  }

  /// Create canonical string from individual fields
  static String _createCanonicalFieldString(
    Map<String, dynamic> payload,
    dynamic timestamp,
    String nonce,
    HmacConfig config,
  ) {
    final parts = <String>[];

    if (config.includeTimestampInSignature) {
      parts.add(timestamp.toString());
    }

    if (config.includeNonceInSignature) {
      parts.add(nonce);
    }

    List<String> fields;
    if (config.canonicalFields != null) {
      fields = config.canonicalFields!;
    } else {
      fields = payload.keys.toList()..sort();
    }

    for (final field in fields) {
      final value = payload[field];

      String stringValue;
      if (value == null) {
        stringValue = '';
      } else if (value is bool) {
        stringValue = value ? '1' : '0';
      } else if (value is Map || value is List) {
        stringValue = jsonEncode(value);
      } else {
        stringValue = value.toString();
      }

      parts.add(stringValue);
    }

    return parts.join(config.separator);
  }

  /// Create JSON string for signing
  static String _createJsonString(
    Map<String, dynamic> payload,
    dynamic timestamp,
    String nonce,
    HmacConfig config,
  ) {
    final signaturePayload = <String, dynamic>{
      if (config.includeTimestampInSignature) 'timestamp': timestamp,
      if (config.includeNonceInSignature) 'nonce': nonce,
      ...payload,
    };

    if (config.sortJsonKeys) {
      final sortedKeys = signaturePayload.keys.toList()..sort();
      final sortedMap = <String, dynamic>{};
      for (final key in sortedKeys) {
        sortedMap[key] = signaturePayload[key];
      }
      return jsonEncode(sortedMap);
    } else {
      return jsonEncode(signaturePayload);
    }
  }

  /// Generate HMAC signature
  static String _generateHmac(
    String data,
    String secretKey,
    HmacConfig config,
  ) {
    try {
      // Select hash algorithm
      Hash hashAlgo;
      switch (config.hashAlgorithm) {
        case 'sha256':
          hashAlgo = sha256;
          break;
        case 'sha512':
          hashAlgo = sha512;
          break;
        case 'sha384':
          hashAlgo = sha384;
          break;
        case 'sha1':
          hashAlgo = sha1;
          break;
        case 'md5':
          hashAlgo = md5;
          break;
        default:
          throw ArgumentError(
            'Unsupported hash algorithm: ${config.hashAlgorithm}',
          );
      }

      // Create HMAC
      final hmacSha = Hmac(hashAlgo, utf8.encode(secretKey));
      final digest = hmacSha.convert(utf8.encode(data));

      // Encode output
      String result;
      switch (config.encoding) {
        case 'hex':
          result = digest.toString();
          break;
        case 'base64':
          result = base64.encode(digest.bytes);
          break;
        case 'base64url':
          result = base64Url
              .encode(digest.bytes)
              .replaceAll('=', ''); // Remove padding
          break;
        default:
          throw ArgumentError('Unsupported encoding: ${config.encoding}');
      }

      return result;
    } catch (e) {
      throw Exception(
        '[_generateHmac] Failed to generate HMAC: $e\n'
        'Algorithm: ${config.hashAlgorithm}, Encoding: ${config.encoding}',
      );
    }
  }

  /// Timing-safe string comparison to prevent timing attacks
  static bool _timingSafeEqual(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }
}
