import 'dart:typed_data';
import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('FaceAligner Tests', () {
    test('aligns face into normalized 112x112 FaceImage', () {
      final img = FaceImage.fromGrayscale(Uint8List(200 * 200), 200, 200);
      final face = Face(boundingBox: Rect(20, 20, 160, 160), confidence: 0.95);

      final landmarkDetector = LandmarkDetector();
      final landmarks = landmarkDetector.detectLandmarks(img, face);

      final aligner = FaceAligner();
      final alignedFace = aligner.alignFace(img, face, landmarks);

      expect(alignedFace.width, equals(112));
      expect(alignedFace.height, equals(112));
    });

    test('throws ValidationException if landmarks count is invalid', () {
      final img = FaceImage.fromGrayscale(Uint8List(50 * 50), 50, 50);
      final face = Face(boundingBox: Rect(5, 5, 40, 40), confidence: 0.9);

      final aligner = FaceAligner();
      expect(
        () => aligner.alignFace(img, face, []),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
