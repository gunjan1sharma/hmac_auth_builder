# hmac_auth_builder

HMAC-based request signing for Dart and Flutter, designed for secure API authentication and webhook verification. The library produces signatures that are compatible with the Node.js package `hmac-auth-builder`, enabling consistent verification between mobile clients and backend services.

[![pub package](https://img.shields.io/pub/v/hmac_auth_builder.svg)](https://pub.dev/packages/hmac_auth_builder)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Overview

`hmac_auth_builder` provides:

- Deterministic HMAC signatures for request authentication.
- Canonical string signing to avoid JSON serialization differences.
- Multiple hash algorithms and encodings.
- Timestamp and nonce support for replay protection.
- Full interoperability with the Node.js `hmac-auth-builder` package.

It is intended for:

- Mobile apps (Flutter) calling secure backend APIs.
- Clients that must generate signatures verified by a Node.js service.
- Webhook providers/consumers that need cross-platform HMAC signing.

---

## Installation

Add the dependency in `pubspec.yaml`:

```yaml
dependencies:
  hmac_auth_builder: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## Basic Usage

```dart
import 'package:hmac_auth_builder/hmac_operations.dart';

void main() {
  final payload = {
    'transaction_id': 'TXN-2026-001',
    'amount': 5000,
    'currency': 'USD',
  };

  const secretKey = 'your-secret-key';

  // Generate signature
  final result = HmacOperations.generateSignature(
    payload,
    secretKey,
  );

  print('Timestamp: ${result.timestamp}');
  print('Nonce: ${result.nonce}');
  print('Signature: ${result.signature}');
  print('Algorithm: ${result.algorithm}');
  print('Canonical: ${result.canonicalString}');
}
```

---

## Verifying a Signature

Use this when you receive a signed request in a Dart server, or for local verification in tests.

```dart
import 'package:hmac_auth_builder/hmac_operations.dart';

void verifyRequest(
  Map<String, dynamic> payload,
  String secretKey,
  String receivedSignature,
  String receivedTimestamp,
  String receivedNonce,
) {
  final verification = HmacOperations.verifySignature(
    payload,
    secretKey,
    receivedSignature,
    receivedTimestamp,
    receivedNonce,
    config: const VerificationConfig(
      timestampTolerance: 180000, // 3 minutes in milliseconds
    ),
  );

  if (!verification.valid) {
    throw StateError('Invalid signature: ${verification.error}');
  }

  // Proceed with handling the request
}
```

---

## Cross-Platform Compatibility (Node.js ↔ Dart)

The library is designed to produce exactly the same canonical string and signature as the Node.js implementation, given identical inputs.

**Dart:**

```dart
import 'package:hmac_auth_builder/hmac_operations.dart';

void main() {
  final payload = {
    'property_id': 'PROP123',
    'aadhaar_number': '123456789012',
    'consent': true,
  };

  const secret = 'ALT_TM_ADMINNLT65XER';
  const fixedTimestamp = 1700000000000;
  const fixedNonce = 'test-nonce-12345';

  final result = HmacOperations.generateSignature(
    payload,
    secret,
    config: const HmacConfig(
      customTimestamp: fixedTimestamp,
      customNonce: fixedNonce,
    ),
  );

  print('Timestamp: ${result.timestamp}');
  print('Nonce: ${result.nonce}');
  print('Canonical: ${result.canonicalString}');
  print('Signature: ${result.signature}');
}
```

**Node.js (hmac-auth-builder):**

```typescript
import { HmacOperations } from "hmac-auth-builder";

const payload = {
  property_id: "PROP123",
  aadhaar_number: "123456789012",
  consent: true,
};

const secret = "ALT_TM_ADMINNLT65XER";
const fixedTimestamp = 1700000000000;
const fixedNonce = "test-nonce-12345";

const result = HmacOperations.generateSignature(payload, secret, {
  customTimestamp: fixedTimestamp,
  customNonce: fixedNonce,
});

console.log("Timestamp:", result.timestamp);
console.log("Nonce:", result.nonce);
console.log("Canonical:", result.canonicalString);
console.log("Signature:", result.signature);
```

The canonical string and signature from Dart and Node.js should match byte-for-byte when you use the same payload, secret, timestamp, and nonce.

---

## Configuration

`HmacConfig` lets you control how signatures are produced.

```dart
const config = HmacConfig(
  signatureMethod: 'canonical',        // 'canonical' or 'json'
  separator: '|',                      // separator between fields
  canonicalFields: ['user_id', 'amount', 'currency'],
  hashAlgorithm: 'sha256',             // 'sha256', 'sha512', 'sha384', 'sha1', 'md5'
  encoding: 'hex',                     // 'hex', 'base64', 'base64url'
  timestampFormat: 'milliseconds',     // 'milliseconds', 'seconds', 'unix', 'iso8601'
  nonceFormat: 'uuid-v4',             // 'uuid-v4', 'uuid-v1', 'random-hex', 'random-base64', 'custom'
  includeTimestampInSignature: true,
  includeNonceInSignature: true,
  sortJsonKeys: true,
);
```

### Example with Custom Configuration

```dart
final result = HmacOperations.generateSignature(
  {
    'user_id': '123',
    'amount': 5000,
    'currency': 'INR',
  },
  'your-secret-key',
  config: const HmacConfig(
    hashAlgorithm: 'sha512',
    encoding: 'base64',
    canonicalFields: ['user_id', 'amount', 'currency'],
    separator: '::',
  ),
);
```

---

## Typical Flutter Integration

A simple pattern for signing API requests from a Flutter app:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hmac_auth_builder/hmac_operations.dart';

class ApiClient {
  ApiClient(this._baseUrl, this._secretKey);

  final String _baseUrl;
  final String _secretKey;

  Future<http.Response> post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final auth = HmacOperations.generateSignature(
      payload,
      _secretKey,
    );

    final uri = Uri.parse('$_baseUrl$path');

    return http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Timestamp': auth.timestamp.toString(),
        'X-Nonce': auth.nonce,
        'X-Signature': auth.signature,
      },
      body: jsonEncode(payload),
    );
  }
}
```

On the backend, you verify the same headers and payload using the Node.js `hmac-auth-builder` package.

---

## Testing

Run the package tests:

```bash
flutter test
```

For local cross-platform verification, you can:

- Generate a signature in Dart with fixed `customTimestamp` and `customNonce`.
- Generate a signature in Node.js with the same fixed values.
- Confirm that canonical string and signature match.

---

## License

This package is available under the MIT License. See the `LICENSE` file for details.

---

## Author

**Gunjan Sharma**  
Tech Lead working across security, blockchain, and distributed systems. Focused on building reliable, auditable primitives that are easy to adopt across platforms (Node.js, Dart/Flutter, mobile, and backend services).

- Avatar: `https://camo.githubusercontent.com/29b56cf13f6ce445c37381881d3ce3665c61d007796297a6f649598c952e80a1/68747470733a2f2f6d656469612e6c6963646e2e636f6d2f646d732f696d6167652f76322f44344430334151454934565f456c3334546f772f70726f66696c652d646973706c617970686f746f2d736872696e6b5f3430305f3430302f4234445a57304c336e784859416b2d2f302f313734323438343736363435373f653d3137373038353434303026763d6265746126743d426f6952517538457463564e7856322d726149564c32796464697376414d6454346d5a3149714f45784851`
- Email: [gunjan.sharmo@gmail.com](mailto:gunjan.sharmo@gmail.com)
- LinkedIn: [https://www.linkedin.com/in/gunjan1sharma](https://www.linkedin.com/in/gunjan1sharma)
- GitHub: [https://github.com/gunjan1sharma](https://github.com/gunjan1sharma)

If you find this library useful, consider starring the repository and sharing feedback or improvement ideas via issues or pull requests.

```

```
