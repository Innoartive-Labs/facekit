import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('FaceKitException Tests', () {
    test('InvalidImageException formatting', () {
      const ex = InvalidImageException('Corrupt buffer', 'Zero length');
      expect(ex.message, equals('Corrupt buffer'));
      expect(ex.details, equals('Zero length'));
      expect(ex.toString(), contains('InvalidImageException: Corrupt buffer (Details: Zero length)'));
    });

    test('FaceDetectionException formatting without details', () {
      const ex = FaceDetectionException('No faces found');
      expect(ex.toString(), equals('FaceDetectionException: No faces found'));
    });

    test('All exception types inherit from FaceKitException', () {
      expect(const InvalidImageException('msg'), isA<FaceKitException>());
      expect(const ModelInitializationException('msg'), isA<FaceKitException>());
      expect(const FaceDetectionException('msg'), isA<FaceKitException>());
      expect(const DatabaseException('msg'), isA<FaceKitException>());
      expect(const SerializationException('msg'), isA<FaceKitException>());
      expect(const ValidationException('msg'), isA<FaceKitException>());
    });
  });
}
