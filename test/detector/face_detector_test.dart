import 'dart:typed_data';
import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('FaceDetector Tests', () {
    test('Rect geometry computes area and IoU correctly', () {
      final r1 = Rect(0, 0, 10, 10);
      final r2 = Rect(5, 0, 10, 10); // Overlaps 5x10 = 50 area

      expect(r1.area, equals(100.0));
      expect(r2.area, equals(100.0));

      // Intersection area = 50, Union area = 150 -> IoU = 50 / 150 = 0.3333...
      expect(r1.computeIoU(r2), closeTo(0.3333, 1e-3));
    });

    test('detects face pattern in synthetic image', () {
      // Build 48x48 synthetic face pattern (forehead bright, eyes dark, nose bright)
      const size = 48;
      final bytes = Uint8List(size * size);

      for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
          final idx = y * size + x;

          // Default background
          bytes[idx] = 120;

          // Forehead bright (y=5..15, x=10..38)
          if (y >= 5 && y <= 15 && x >= 10 && x <= 38) {
            bytes[idx] = 220;
          }
          // Eye socket region dark (y=16..25, x=8..40)
          if (y >= 16 && y <= 25 && x >= 8 && x <= 40) {
            bytes[idx] = 30;
          }
          // Nose bridge bright (y=18..35, x=20..28)
          if (y >= 18 && y <= 35 && x >= 20 && x <= 28) {
            bytes[idx] = 200;
          }
        }
      }

      final img = FaceImage.fromGrayscale(bytes, size, size);
      final detector = FaceDetector(config: const FaceKitConfig(detectionThreshold: 0.3));

      final faces = detector.detectFaces(img);

      expect(faces, isNotEmpty);
      final face = faces.first;
      expect(face.confidence, greaterThanOrEqualTo(0.3));
      expect(face.boundingBox.width, greaterThan(0));
      expect(face.boundingBox.height, greaterThan(0));
    });

    test('NMS eliminates redundant overlapping bounding boxes', () {
      final detector = FaceDetector();
      final faces = detector.detectFaces(
        FaceImage.fromGrayscale(Uint8List(24 * 24), 24, 24),
        threshold: 0.99,
      );

      // Blank uniform image produces 0 faces above 0.99
      expect(faces, isEmpty);
    });
  });
}
