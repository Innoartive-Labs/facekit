<div align="center">

# FaceKit

---

### Pure Dart Offline Facial Recognition Engine — for Dart & Flutter (iOS, Android, Web, Desktop, & Server)

[![CI](https://github.com/Innoartive-Labs/facekit/actions/workflows/ci.yml/badge.svg)](https://github.com/Innoartive-Labs/facekit/actions/workflows/ci.yml)

[![pub](https://img.shields.io/badge/pub-v1.0.0-00B4AB.svg)](https://pub.dev/packages/facekit)
[![points](https://img.shields.io/badge/points-160%2F160-007EC6.svg)]()
[![likes](https://img.shields.io/badge/likes-1-E05D44.svg)]()
[![License](https://img.shields.io/badge/License-MIT-007EC6.svg)](LICENSE)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.0-007EC6.svg)]()
[![Flutter](https://img.shields.io/badge/Flutter-Compatible-007EC6.svg)]()
[![dependencies](https://img.shields.io/badge/dependencies-0-brightgreen.svg)]()

*Built by [Innoartive Labs](https://github.com/Innoartive-Labs) · Zero Dependencies*


---

</div>


## Why Pure Dart?

Developing facial recognition applications on Flutter often involves fighting native build toolchain failures (C++ `CMake`, Android `NDK`, iOS `CocoaPods`, TFLite/ONNX runtime version mismatches).

`FaceKit` takes a different approach by running **100% pure Dart**:

- **Zero Native Dependencies**: No C/C++ bindings, no external ML runtimes (no TensorFlow, no TFLite, no OpenCV, no ONNX, no MediaPipe).
- **100% Cross-Platform**: Runs identically across iOS, Android, Web, macOS, Windows, Linux, and Dart CLI.
- **Tiny Footprint**: Entire engine and model footprint is $\approx 130\text{ KB}$ (compared to 15MB–100MB native models).
- **Architectural Tradeoff**: Designed as a lightweight, fast CPU engine for on-device applications rather than a heavy GPU deep neural network.

---

## Key Features

- **100% Offline Biometrics**: Zero cloud APIs, zero remote network calls, complete user data sovereignty.
- **Fast Local Execution**: Sub-15ms end-to-end latency on Desktop and Mobile CPU engines.
- **Multi-Scale Spatial Descriptor Engine**: Spatial LBP & HOG feature grid descriptor projecting faces onto a 128-dimensional L2 unit hypersphere.
- **Custom Binary Persistence**: Compact `.face` binary format serialization (CRC32-checked) and JSON export/import adapters.

---

## 🔒 Privacy & Architecture Alignment

`FaceKit` is **designed to support GDPR/HIPAA-aligned privacy architectures** by ensuring all biometric data remains strictly on-device:

- **Complete Data Sovereignty**: Landmark extraction, feature embedding, and face matching occur 100% locally in device memory.
- **Zero Remote Telemetry**: No network dependencies, no cloud endpoints, and no remote data collection.
- **Multi-Tenancy Isolation**: Every application runs an isolated in-memory registry instance. Registered data is never shared across apps or organizations.
- **Compliance Note**: While `FaceKit` provides total technical data sovereignty, overall GDPR/HIPAA compliance depends on your host application's user consent flows, retention policies, and security controls.

---

## Technical Specifications Summary

- **Detector**: Multi-scale image pyramid ($24 \times 24$ sliding window) with IoU Non-Maximum Suppression and adaptive contrast fallback.
- **Landmarks**: 68 primary facial keypoints and 468 dense 3D mesh points with pupil intensity minimum search.
- **Alignment**: Similarity transformation leveling eye roll angle ($\theta = \arctan2(\Delta y, \Delta x)$) and normalizing to canonical $112 \times 112$ format.
- **Feature Extractor**: Multi-cell spatial LBP + HOG gradient descriptor projecting onto a 128-dimensional L2-normalized vector ($\|\mathbf{v}\|_2 = 1.0$).

---

## Quick Example

```dart
import 'package:facekit/facekit.dart';

void main() async {
  final facekit = FaceKit();

  // Register a subject
  await facekit.register(
    image: faceImage,
    personId: "EMP001",
    name: "John Doe",
  );

  // Recognize subject from query image
  final result = await facekit.recognize(queryImage);

  if (result.matched) {
    print('Matched Person ID: ${result.personId}');
    print('Name: ${result.name}');
    print('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
  }
}
```

---

## External Database Integration & Persistence

`FaceKit` makes it easy to persist and synchronize face records across external databases such as **SQLite, MySQL, MariaDB, PostgreSQL, Supabase, Firebase, Hive, Isar, or MongoDB**:

```dart
// 1. Extract raw 128D embedding vector bytes (512 bytes)
final Uint8List rawBytes = record.embedding.values.buffer.asUint8List();

// 2. Save into SQLite / PostgreSQL BLOB column:
await db.insert('persons', {
  'person_id': record.personId,
  'name': record.name,
  'embedding_blob': rawBytes,
});

// 3. Load from database and populate FaceKit anytime:
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

// 4. Recognize instantaneously (<0.1 ms in-memory search)
final result = await facekit.recognize(queryImage);
```

### Persistence Formats
- **Compact `.face` Binary Buffer**: `exportPersonBinary('EMP001')` generates a CRC32-checksummed binary buffer (~550 bytes) perfect for BLOB columns or REST APIs.
- **Full JSON Database Export/Import**: `exportDatabaseJson()` and `importDatabaseJson()` convert the entire face registry to/from JSON strings for NoSQL stores like Firebase Cloud Firestore or MongoDB.

---

## ⚠️ Known Limitations & Design Tradeoffs

To ensure correct developer expectations pre-launch:

1. **Pose Sensitivity**: Best suited for frontal and semi-frontal faces ($\le \pm 30^\circ$ yaw/pitch angle).
2. **Illumination Requirements**: Requires reasonable ambient lighting. Includes auto-contrast enhancement pass, but extreme darkness degrades resolution.
3. **Model Footprint vs Deep Networks**: Designed as a lightweight CPU spatial feature engine ($\approx 130\text{ KB}$ footprint) rather than a heavy GPU deep neural network (e.g. 100MB FaceNet).
4. **Liveness Detection**: Liveness anti-spoofing (blink/motion detection) is currently on the development roadmap and not included in v1.0.0.

---

## Performance Benchmarks Summary

*Benchmarked on Intel Core i7 / AMD Ryzen 7, Windows 11, Dart SDK 3.10.8 JIT/AOT mode:*

- **End-to-End Registration Latency**: **$14.90\text{ ms}$** / subject
- **End-to-End Recognition Query Latency**: **$14.30\text{ ms}$** / query
- **`.face` Binary Format Throughput**: **$0.068\text{ ms}$** / operation

For complete hardware details, JIT vs AOT benchmarks, and evaluation metrics, read [`doc/BENCHMARKS.md`](./doc/BENCHMARKS.md).

---

## Documentation Links

- [Technical Architecture Specification](./doc/ARCHITECTURE.md)
- [Performance & Metric Benchmarks](./doc/BENCHMARKS.md)
- [API Reference Guide](./doc/API.md)
- [Future Development Roadmap](./doc/ROADMAP.md)

---

## License & Credits

Developed and maintained by **[Innoartive Labs](https://github.com/Innoartive-Labs)**.


Released under the MIT License.




