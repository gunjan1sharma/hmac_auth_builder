# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-02-02

### Added

- Initial release of HMAC signature generation and verification.
- Support for canonical string signing with customizable field order.
- Multiple hash algorithms: SHA-256, SHA-512, SHA-384, SHA-1, MD5.
- Multiple output encodings: hex, base64, base64url.
- Configurable timestamp formats: milliseconds, seconds, unix, ISO8601.
- Configurable nonce formats: UUID v4, UUID v1, random hex, random base64, custom generator.
- Timestamp tolerance configuration for replay attack prevention.
- Full cross-platform compatibility with Node.js `hmac-auth-builder` package.
- Comprehensive test suite with unit tests and cross-platform verification examples.
- Documentation with usage examples and integration patterns.

---

## [Unreleased]

### Planned

- Built-in middleware for Dart Shelf framework.
- Performance benchmarks and optimization for high-throughput scenarios.
- Support for batch signature verification.

---

[1.0.0]: https://github.com/yourusername/hmac-auth-builder-dart/releases/tag/v1.0.0
