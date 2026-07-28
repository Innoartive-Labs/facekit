import 'dart:typed_data';
import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('LandmarkDetector Tests', () {
    test('detects 68 facial landmarks correctly', () {
      final img = FaceImage.fromGrayscale(Uint8List(100 * 100), 100, 100);
      final face = Face(boundingBox: Rect(10, 10, 80, 80), confidence: 0.9);

      final detector = LandmarkDetector(
        config: const FaceKitConfig(
          landmarkModel: LandmarkModelType.landmarks68,
        ),
      );
      final landmarks = detector.detectLandmarks(img, face);

      expect(landmarks.length, equals(68));
      expect(landmarks.first.index, equals(0));
      expect(landmarks.last.index, equals(67));

      // Right Eye pupil landmark (~index 36) should be inside bounding box (10..90)
      final rightEye = landmarks[36];
      expect(rightEye.x, greaterThan(10));
      expect(rightEye.x, lessThan(90));
      expect(rightEye.y, greaterThan(10));
      expect(rightEye.y, lessThan(90));
    });

    test('detects 468 dense 3D mesh landmarks when configured', () {
      final img = FaceImage.fromGrayscale(Uint8List(100 * 100), 100, 100);
      final face = Face(boundingBox: Rect(10, 10, 80, 80), confidence: 0.95);

      final detector = LandmarkDetector(
        config: const FaceKitConfig(
          landmarkModel: LandmarkModelType.landmarks468,
        ),
      );
      final meshLandmarks = detector.detectLandmarks(img, face);

      expect(meshLandmarks.length, equals(468));
      expect(meshLandmarks.first.z, isNotNull);
    });
  });
}
