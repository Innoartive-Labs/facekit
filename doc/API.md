# FaceKit API Reference Documentation

Complete public API reference for `package:facekit`.

---

## 1. Engine Initialization

```dart
import 'package:facekit/facekit.dart';

// Create engine with default settings
final facekit = FaceKit();

// Create engine with custom configuration
final customFaceKit = FaceKit(
  config: FaceKitConfig(
    detectionThreshold: 0.7,
    matchingThreshold: 0.65,
    distanceMetric: FaceDistanceMetric.cosine,
    landmarkModel: LandmarkModelType.landmarks68,
    logLevel: FaceKitLogLevel.info,
  ),
);
```

---

## 2. Image Processing (`FaceImage`)

```dart
// Create RGB FaceImage from raw bytes
final rgbImage = FaceImage.fromRgb(bytes, width, height);

// Create Grayscale FaceImage from raw bytes
final grayImage = FaceImage.fromGrayscale(bytes, width, height);

// Color format conversions
final gray = rgbImage.toGrayscale();
final rgb = grayImage.toRgb();

// Computer vision transforms
final resized = ImageProcessor.resizeBilinear(rgbImage, 112, 112);
final rotated = ImageProcessor.rotate(rgbImage, 0.5); // Radians
final cropped = ImageProcessor.crop(rgbImage, x, y, width, height);
final blurred = ImageProcessor.gaussianBlur(grayImage, kernelSize: 5);
final sobel = ImageProcessor.sobelEdgeDetection(grayImage);
```

---

## 3. Face Registration (`register`)

```dart
final record = await facekit.register(
  image: image,
  personId: 'EMP001',
  name: 'John Doe',
  metadata: {
    'role': 'Engineer',
    'department': 'R&D',
  },
);

print('Registered subject: ${record.personId} (${record.name})');
```

---

## 4. Face Recognition (`recognize`)

```dart
final result = await facekit.recognize(queryImage);

if (result.matched) {
  print('Matched Person ID: ${result.personId}');
  print('Matched Name: ${result.name}');
  print('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
} else {
  print('Unknown face detected');
}
```

---

## 5. Multi-Face Recognition (`recognizeMultiple`)

```dart
final results = await facekit.recognizeMultiple(multiFaceImage);

for (final res in results) {
  print('Found: ${res.personId} - ${res.name} (Conf: ${res.confidence})');
}
```

---

## 6. Subject Management (`delete` & `update`)

```dart
// Update subject details
await facekit.update(
  personId: 'EMP001',
  name: 'Johnathan Doe',
  newImage: updatedImage,
);

// Delete subject
final deleted = await facekit.delete('EMP001');
```

---

## 7. Database Import & Export

```dart
// Export full database as JSON
final jsonPayload = await facekit.exportDatabaseJson();

// Import database from JSON
await facekit.importDatabaseJson(jsonPayload);

// Export single subject to custom .face binary format
final binaryBytes = await facekit.exportPersonBinary('EMP001');

// Import subject from .face binary format
final record = await facekit.importPersonBinary(binaryBytes);
```
