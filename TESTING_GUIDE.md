# 🧪 Testing Your Dart HMAC Package Locally

## Step-by-Step Local Testing Guide

### 1. Create Flutter Project Structure

```bash
# Create project directory
mkdir hmac_auth_builder_dart
cd hmac_auth_builder_dart

# Create standard Flutter package structure
mkdir -p lib test example

# Move files to correct locations
mv hmac_operations.dart lib/
mv hmac_operations_test.dart test/
mv example_main.dart example/main.dart
mv pubspec.yaml .
mv README_DART.md README.md
```

### 2. Install Dependencies

```bash
# Get all dependencies
flutter pub get

# Expected output:
# Resolving dependencies...
# + crypto 3.0.3
# + uuid 4.3.3
# + test 1.25.2
# Got dependencies!
```

### 3. Run Tests

```bash
# Run all tests
flutter test

# Run with verbose output
flutter test --verbose

# Run specific test file
flutter test test/hmac_operations_test.dart
```

### 4. Run Example

```bash
# Run the example
dart run example/main.dart

# Expected output:
# 🔐 HMAC Auth Builder - Dart/Flutter Example
# ...signature output...
```

---

## 🔄 Cross-Platform Compatibility Test

### Test Setup

Create these test files in both Node.js and Dart projects:

#### Node.js Test (`test_compatibility.js`)

```javascript
const { HmacOperations } = require('hmac-auth-builder');

// Fixed test values
const payload = {
  property_id: 'PROP123',
  aadhaar_number: '123456789012',
  consent: true
};
const secret = 'ALT_TM_ADMINNLT65XER';
const timestamp = 1700000000000;
const nonce = 'test-nonce-12345';

const result = HmacOperations.generateSignature(
  payload,
  secret,
  { customTimestamp: timestamp, customNonce: nonce }
);

console.log('=== Node.js Output ===');
console.log('Timestamp:', result.timestamp);
console.log('Nonce:', result.nonce);
console.log('Canonical:', result.canonicalString);
console.log('Signature:', result.signature);
```

#### Dart Test (`test_compatibility.dart`)

```dart
import 'package:hmac_auth_builder/hmac_operations.dart';

void main() {
  // Fixed test values (same as Node.js)
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

  print('=== Dart Output ===');
  print('Timestamp: ${result.timestamp}');
  print('Nonce: ${result.nonce}');
  print('Canonical: ${result.canonicalString}');
  print('Signature: ${result.signature}');
}
```

### Run Compatibility Test

```bash
# In Node.js project
node test_compatibility.js

# In Dart project
dart run test_compatibility.dart

# Compare outputs - they should be IDENTICAL!
```

---

## 📱 Test in Real Flutter App

### 1. Create New Flutter App

```bash
flutter create test_hmac_app
cd test_hmac_app
```

### 2. Add Dependency

Edit `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  hmac_auth_builder:
    path: ../hmac_auth_builder_dart  # Local path
```

### 3. Install

```bash
flutter pub get
```

### 4. Use in App

Edit `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:hmac_auth_builder/hmac_operations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('HMAC Test')),
        body: Center(
          child: ElevatedButton(
            onPressed: _testSignature,
            child: Text('Generate Signature'),
          ),
        ),
      ),
    );
  }

  void _testSignature() {
    final result = HmacOperations.generateSignature(
      {'test': 'data', 'user_id': '123'},
      'secret-key',
    );

    print('✅ Signature: ${result.signature}');
    print('Timestamp: ${result.timestamp}');
    print('Nonce: ${result.nonce}');
  }
}
```

### 5. Run App

```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter devices
flutter run -d <device-id>
```

---

## 🔍 Verify Signature with Node.js Backend

### Complete Integration Test

#### 1. Start Node.js Server

```javascript
// server.js
const express = require('express');
const { HmacOperations } = require('hmac-auth-builder');

const app = express();
app.use(express.json());

app.post('/verify', (req, res) => {
  const { payload, signature, timestamp, nonce } = req.body;
  const secret = 'test-secret-key';

  const verification = HmacOperations.verifySignature(
    payload,
    secret,
    signature,
    timestamp,
    nonce
  );

  res.json({
    valid: verification.valid,
    error: verification.error,
    timestampAge: verification.timestampAge
  });
});

app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});
```

```bash
node server.js
```

#### 2. Flutter Client

```dart
import 'package:http/http.dart' as http;
import 'package:hmac_auth_builder/hmac_operations.dart';
import 'dart:convert';

Future<void> testWithBackend() async {
  final payload = {'test': 'data', 'user_id': '123'};
  const secret = 'test-secret-key';

  // Generate signature in Flutter
  final auth = HmacOperations.generateSignature(payload, secret);

  print('📱 Flutter generated:');
  print('  Signature: ${auth.signature}');
  print('  Timestamp: ${auth.timestamp}');
  print('  Nonce: ${auth.nonce}');

  // Send to Node.js for verification
  final response = await http.post(
    Uri.parse('http://localhost:3000/verify'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'payload': payload,
      'signature': auth.signature,
      'timestamp': auth.timestamp,
      'nonce': auth.nonce,
    }),
  );

  final result = jsonDecode(response.body);

  if (result['valid']) {
    print('✅ SUCCESS! Node.js verified Flutter signature!');
  } else {
    print('❌ FAILED: ${result['error']}');
  }
}

void main() async {
  await testWithBackend();
}
```

```bash
flutter pub add http
dart run test_backend.dart
```

**Expected output:**
```
📱 Flutter generated:
  Signature: a3f7b8c2d9e1f5g6...
  Timestamp: 1737623400000
  Nonce: 550e8400-e29b-41d4...
✅ SUCCESS! Node.js verified Flutter signature!
```

---

## 🐛 Troubleshooting

### Issue 1: "Package hmac_auth_builder not found"

```bash
# Check pubspec.yaml is correct
cat pubspec.yaml

# Clean and reinstall
flutter clean
flutter pub get
```

### Issue 2: "Signature mismatch between Node.js and Dart"

```bash
# Print canonical strings from both:
# Node.js:
console.log('Canonical:', result.canonicalString);

# Dart:
print('Canonical: ${result.canonicalString}');

# They MUST be identical!
```

**Common causes:**
- Different field order (should be alphabetical)
- Boolean conversion (true → '1', false → '0')
- Null handling (null → '')
- Timestamp format mismatch

### Issue 3: "Test fails with timing issues"

```dart
// Use fixed timestamp for tests
const config = HmacConfig(
  customTimestamp: 1700000000000,
  customNonce: 'fixed-nonce',
);
```

---

## ✅ Testing Checklist

Before publishing:

- [ ] All unit tests pass (`flutter test`)
- [ ] Example runs without errors (`dart run example/main.dart`)
- [ ] Signatures match Node.js version (compatibility test)
- [ ] Works in real Flutter app
- [ ] Backend verification works
- [ ] No analyzer warnings (`flutter analyze`)
- [ ] Documentation is complete
- [ ] README has correct examples

---

## 📊 Performance Testing

```dart
import 'dart:io';

void performanceTest() {
  final payload = {'user_id': '123', 'amount': 1000};
  const secret = 'test-secret-key';
  const iterations = 1000;

  final stopwatch = Stopwatch()..start();

  for (int i = 0; i < iterations; i++) {
    HmacOperations.generateSignature(payload, secret);
  }

  stopwatch.stop();

  final avgTime = stopwatch.elapsedMicroseconds / iterations;
  print('Average time per signature: ${avgTime.toStringAsFixed(2)}μs');
  print('Throughput: ${(1000000 / avgTime).toInt()} signatures/sec');
}
```

**Expected performance:**
- Mobile (Debug): ~1-5ms per signature
- Mobile (Release): ~0.5-2ms per signature
- Desktop: ~0.2-1ms per signature

---

## 🚀 Ready to Publish?

Once all tests pass:

```bash
# 1. Update version in pubspec.yaml
# 2. Format code
dart format .

# 3. Analyze for issues
flutter analyze

# 4. Dry run publish
flutter pub publish --dry-run

# 5. Publish to pub.dev
flutter pub publish
```

---

**Your Dart package is now fully tested and ready!** 🎉
