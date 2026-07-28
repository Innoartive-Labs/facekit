<div align="center">

# facekit

**100% Pure Dart Offline Facial Recognition Engine — for Dart & Flutter (iOS, Android, Web, Desktop, & Server)**

[![CI](https://github.com/Innoartive-Labs/facekit/actions/workflows/ci.yml/badge.svg?style=flat-square)](https://github.com/Innoartive-Labs/facekit/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/facekit.svg?style=flat-square&color=00B4AB)](https://pub.dev/packages/facekit)
[![Pub Points](https://img.shields.io/pub/points/facekit?style=flat-square&color=blue)](https://pub.dev/packages/facekit/score)
[![Pub Likes](https://img.shields.io/pub/likes/facekit?style=flat-square&color=red)](https://pub.dev/packages/facekit)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Dart SDK](https://img.shields.io/badge/Dart-%3E%3D3.0-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-Compatible-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Zero Dependencies](https://img.shields.io/badge/dependencies-0-brightgreen?style=flat-square)](https://pub.dev/packages/facekit)

*Built by [Innoartive Labs](https://github.com/Innoartive-Labs) · Zero Dependencies*

</div>

---

## What is facekit?

**facekit** is a production-grade facial recognition engine built entirely in **100% pure Dart**, designed for seamless integration across **Flutter and Dart applications (iOS, Android, Web, macOS, Windows, Linux, and Server)**.

It executes the complete facial recognition pipeline locally on-device: face detection, 68-point facial keypoint localization, 468-point 3D mesh interpolation, eye-roll alignment to a canonical $112 \times 112$ format, 128-dimensional spatial feature descriptor extraction (Local Binary Patterns + HOG gradients), and nearest-neighbor vector matching—all with **zero native dependencies** and **zero cloud network calls**.

---

## Why FaceKit?

| Feature | facekit | Typical ML Pipeline (TFLite / ONNX) |
| :--- | :---: | :---: |
| **Zero Native Dependencies** | ✅ | ❌ (NDK, CMake, CocoaPods headaches) |
| **100% Offline Biometrics** | ✅ | Varies |
| **Cross-Platform Parity** | ✅ | ❌ (Web & Desktop build issues) |
| **Tiny Footprint** | ✅ ($\approx 130\text{ KB}$) | ❌ ($15\text{MB} - 100\text{MB}$ models) |
| **Custom Binary Persistence** | ✅ (`.face` CRC32) | ❌ |
| **Pluggable DB Adapters** | ✅ (SQLite, Postgres, NoSQL) | ❌ |
| **Predictable CPU Latency** | ✅ ($<15\text{ ms}$) | Varies |

### Key Highlights:

1. **Zero Toolchain Friction**: Eliminates native build failures across C++ compilers, Android NDK, iOS CocoaPods, and ML runtime version mismatches.
2. **100% Data Sovereignty**: All biometric calculations occur strictly in device RAM. No images or feature vectors ever leave the device.
3. **Multi-Scale Spatial Cell Descriptor**: Computes L2-normalized 128-dimensional spatial grid descriptors (LBP texture histograms, HOG gradient orientation, and cell intensity variance).
4. **CRC32-Validated Persistence**: Includes a custom binary format (`.face`) with magic header `0x46414345` and 32-bit CRC32 checksum integrity verification.

---

## Installation

Add `facekit` to your `pubspec.yaml`:

```yaml
dependencies:
  facekit: ^1.0.0
```

Or run:

```bash
flutter pub add facekit
# Or for Dart CLI / Server
dart pub add facekit
```

---

## Quick Start

```dart
import 'package:facekit/facekit.dart';

void main() async {
  // Initialize FaceKit engine
  final facekit = FaceKit();

  // 1. Register a new subject
  await facekit.register(
    image: faceImage,
    personId: "EMP001",
    name: "John Doe",
  );

  // 2. Recognize subject from query image
  final result = await facekit.recognize(queryImage);

  if (result.matched) {
    print('Matched Person ID: ${result.personId}');
    print('Name: ${result.name}');
    print('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
  }
}
```

---

## Core Features & Usage

### 1. Subject Management (`register`, `recognize`, `update`, `delete`)

```dart
// Register a subject with metadata
final record = await facekit.register(
  image: faceImage,
  personId: 'EMP001',
  name: 'Jane Doe',
  metadata: {'department': 'Engineering'},
);

// Update existing subject template
await facekit.update(
  personId: 'EMP001',
  name: 'Jane Doe',
  newImage: updatedFaceImage,
);

// Recognize multiple faces in a single frame
final results = await facekit.recognizeMultiple(multiFaceImage);

// Delete subject from in-memory registry
final deleted = await facekit.delete('EMP001');
```

---

### 2. External Database Persistence (SQLite, PostgreSQL, Firebase)

`facekit` embeddings are 128-dimensional floating point vectors ($512\text{ bytes}$) that can be persisted in any database:

```dart
// 1. Extract raw 128D embedding vector bytes
final Uint8List rawBytes = record.embedding.values.buffer.asUint8List();

// 2. Save into SQLite / PostgreSQL BLOB column:
await db.insert('persons', {
  'person_id': record.personId,
  'name': record.name,
  'embedding_blob': rawBytes,
});

// 3. Load from database and populate FaceKit on app start:
final rows = await db.query('persons');
for (final row in rows) {
  final Uint8List blob = row['embedding_blob'];
  facekit.matcher.addRecord(
    PersonRecord(
      personId: row['person_id'],
      name: row['name'],
      embedding: FaceEmbedding(Float32List.view(blob.buffer)),
    ),
  );
}

// 4. Recognize instantaneously (<0.1 ms in-memory query)
final result = await facekit.recognize(queryImage);
```

### Persistence Formats
- **Compact `.face` Binary Buffer**: `exportPersonBinary('EMP001')` generates a CRC32-checked binary buffer ($\approx 550\text{ bytes}$) ideal for BLOB storage or REST APIs.
- **Full JSON Database Export/Import**: `exportDatabaseJson()` and `importDatabaseJson()` convert the entire face registry to/from JSON payload strings for NoSQL stores like Firebase Cloud Firestore or MongoDB.

---

## 🔒 Privacy & Architecture Alignment

`facekit` is **designed to support GDPR/HIPAA-aligned privacy architectures** by keeping all biometric operations strictly on-device:

- **Complete Data Sovereignty**: Feature extraction, landmark localization, and vector matching execute 100% locally in device memory.
- **Zero Remote Telemetry**: No network dependencies, no cloud endpoints, and no remote data collection.
- **Multi-Tenancy Isolation**: Every application runs an isolated in-memory registry instance. Registered face data is never shared across apps or organizations.
- **Compliance Note**: While `facekit` provides technical data sovereignty, overall GDPR/HIPAA compliance depends on your host application's user consent flows, retention policies, and security controls.

---

## ⚠️ Known Limitations & Design Tradeoffs

To ensure correct developer expectations pre-launch:

1. **Pose Sensitivity**: Best performance achieved on frontal and semi-frontal faces ($\le \pm 30^\circ$ yaw/pitch angle).
2. **Illumination Requirements**: Requires reasonable ambient lighting. Includes auto-contrast enhancement fallback pass, but extreme darkness degrades resolution.
3. **Model Footprint vs Deep Networks**: Designed as a lightweight CPU spatial feature engine ($\approx 130\text{ KB}$ footprint) rather than a heavy GPU deep neural network (e.g. 100MB FaceNet).
4. **Liveness Detection**: Liveness anti-spoofing (blink/motion detection) is currently on the development roadmap and not included in v1.0.0.

---

## Advanced Usage & Benchmarks

*Benchmarked on Intel Core i7 / AMD Ryzen 7, Windows 11, Dart SDK 3.10.8 JIT/AOT mode:*

| Operation | Latency (JIT Mode) | Latency (AOT Mode) | Throughput / FPS |
| :--- | :--- | :--- | :--- |
| **Face Detection** ($48 \times 48$) | $12.10\text{ ms}$ | $6.20\text{ ms}$ | ~160 FPS |
| **Landmark Localization** (68 points) | $0.85\text{ ms}$ | $0.42\text{ ms}$ | ~2,380 FPS |
| **Face Alignment** ($112 \times 112$) | $0.75\text{ ms}$ | $0.38\text{ ms}$ | ~2,630 FPS |
| **Spatial Feature Extraction** (128D) | $0.45\text{ ms}$ | $0.22\text{ ms}$ | ~4,500 ops/sec |
| **End-to-End Registration** | **$14.15\text{ ms}$** | **$7.20\text{ ms}$** | **~140 ops/sec** |
| **End-to-End Recognition Query** | **$13.55\text{ ms}$** | **$6.80\text{ ms}$** | **~145 ops/sec** |

To measure performance in your local environment, run the included benchmark scripts:

```bash
# Run performance benchmark
dart run test/benchmarks/performance_benchmark.dart

# Run accuracy benchmark
dart run test/benchmarks/accuracy_benchmark.dart
```

---

## Documentation Links

- [Technical Architecture Specification](./doc/ARCHITECTURE.md)
- [Performance & Metric Benchmarks](./doc/BENCHMARKS.md)
- [API Reference Guide](./doc/API.md)
- [Future Development Roadmap](./doc/ROADMAP.md)

---

## License

MIT © [Innoartive Labs](https://github.com/Innoartive-Labs)

