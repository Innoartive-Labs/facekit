import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('FaceKitConfig Tests', () {
    test('default configuration values', () {
      const config = FaceKitConfig.defaultConfig;
      expect(config.detectionThreshold, equals(0.5));
      expect(config.matchingThreshold, equals(0.65));
      expect(config.distanceMetric, equals(FaceDistanceMetric.cosine));

      expect(config.landmarkModel, equals(LandmarkModelType.landmarks68));
      expect(config.embeddingDimension, equals(128));
      expect(config.targetFaceSize, equals(112));
      expect(config.maxDetectedFaces, equals(10));
      expect(config.logLevel, equals(FaceKitLogLevel.info));
    });

    test('copyWith modifies specified fields', () {
      const config = FaceKitConfig.defaultConfig;
      final updated = config.copyWith(
        detectionThreshold: 0.8,
        matchingThreshold: 0.75,
        distanceMetric: FaceDistanceMetric.euclidean,
        landmarkModel: LandmarkModelType.landmarks468,
        logLevel: FaceKitLogLevel.debug,
      );

      expect(updated.detectionThreshold, equals(0.8));
      expect(updated.matchingThreshold, equals(0.75));
      expect(updated.distanceMetric, equals(FaceDistanceMetric.euclidean));
      expect(updated.landmarkModel, equals(LandmarkModelType.landmarks468));
      expect(updated.logLevel, equals(FaceKitLogLevel.debug));
      expect(updated.targetFaceSize, equals(112));
    });

    test('equality and hashCode', () {
      const config1 = FaceKitConfig(detectionThreshold: 0.7);
      const config2 = FaceKitConfig(detectionThreshold: 0.7);
      const config3 = FaceKitConfig(detectionThreshold: 0.9);

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1, isNot(equals(config3)));
    });
  });
}
