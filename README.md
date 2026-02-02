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

---

## 👨‍💻 Author

<div align="center">

<img src="https://media.licdn.com/dms/image/v2/D4D03AQEI4V_El34Tow/profile-displayphoto-shrink_400_400/B4DZW0L3nxHYAk-/0/1742484766457?e=1770854400&v=beta&t=BoiRQu8EtcVNxV2-raIVL2yddisvAMdT4mZ1IqOExHQ" alt="Gunjan Sharma" width="120" height="120" style="border-radius: 50%; border: 3px solid #0366d6;" />

### Gunjan Sharma

**Full Stack Architect & Security Engineer**

Building secure, scalable systems for fintech and enterprise applications. Specializing in API security, microservices architecture, and blockchain integrations.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/gunjan1sharma)
[![Email](https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:gunjan.sharmo@gmail.com)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/gunjan1sharma)
[![Website](https://img.shields.io/badge/Website-4285F4?style=for-the-badge&logo=google-chrome&logoColor=white)](https://gunjan1sharma.web.app)

**Open for:**

- 🔐 Security audits and consulting
- 🚀 System architecture reviews
- 💼 Freelance projects
- 🤝 Technical collaborations

</div>

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

Copyright © 2026 Gunjan Sharma

---

## 🙏 Acknowledgments

- Inspired by [Stripe's webhook signature verification](https://stripe.com/docs/webhooks/signatures)
- HMAC implementation follows [RFC 2104](https://www.ietf.org/rfc/rfc2104.txt)
- Timing-safe comparison based on [OpenSSL's approach](https://www.openssl.org/)

---
