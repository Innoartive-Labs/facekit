import 'logger.dart';

/// Distance metric used for face embedding comparisons.
enum FaceDistanceMetric {
  /// Cosine similarity score (higher is more similar, 1.0 = identical).
  cosine,

  /// Euclidean L2 distance (lower is more similar, 0.0 = identical).
  euclidean,
}

/// Landmark model type supported by FaceKit.
enum LandmarkModelType {
  /// Standard 68-point facial landmarks.
  landmarks68,

  /// Dense 468-point 3D facial mesh landmarks.
  landmarks468,
}

/// Immutable configuration class for FaceKit operations.
class FaceKitConfig {
  /// Confidence threshold for face detection (0.0 to 1.0).
  final double detectionThreshold;

  /// Similarity threshold for face matching decision (0.0 to 1.0).
  final double matchingThreshold;

  /// Distance metric for embedding comparison.
  final FaceDistanceMetric distanceMetric;

  /// Facial landmark model type.
  final LandmarkModelType landmarkModel;

  /// Dimensionality of face feature vectors (embeddings).
  final int embeddingDimension;

  /// Target side dimension (pixels) for face normalization and alignment.
  final int targetFaceSize;

  /// Maximum number of faces to detect per image query.
  final int maxDetectedFaces;

  /// Active log verbosity level.
  final FaceKitLogLevel logLevel;

  /// Creates a new immutable [FaceKitConfig] instance.
  const FaceKitConfig({
    this.detectionThreshold = 0.5,
    this.matchingThreshold = 0.65,
    this.distanceMetric = FaceDistanceMetric.cosine,
    this.landmarkModel = LandmarkModelType.landmarks68,
    this.embeddingDimension = 128,
    this.targetFaceSize = 112,
    this.maxDetectedFaces = 10,
    this.logLevel = FaceKitLogLevel.info,
  });


  /// Default configuration instance.
  static const FaceKitConfig defaultConfig = FaceKitConfig();

  /// Returns a new copy of [FaceKitConfig] with updated properties.
  FaceKitConfig copyWith({
    double? detectionThreshold,
    double? matchingThreshold,
    FaceDistanceMetric? distanceMetric,
    LandmarkModelType? landmarkModel,
    int? embeddingDimension,
    int? targetFaceSize,
    int? maxDetectedFaces,
    FaceKitLogLevel? logLevel,
  }) {
    return FaceKitConfig(
      detectionThreshold: detectionThreshold ?? this.detectionThreshold,
      matchingThreshold: matchingThreshold ?? this.matchingThreshold,
      distanceMetric: distanceMetric ?? this.distanceMetric,
      landmarkModel: landmarkModel ?? this.landmarkModel,
      embeddingDimension: embeddingDimension ?? this.embeddingDimension,
      targetFaceSize: targetFaceSize ?? this.targetFaceSize,
      maxDetectedFaces: maxDetectedFaces ?? this.maxDetectedFaces,
      logLevel: logLevel ?? this.logLevel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaceKitConfig &&
          runtimeType == other.runtimeType &&
          detectionThreshold == other.detectionThreshold &&
          matchingThreshold == other.matchingThreshold &&
          distanceMetric == other.distanceMetric &&
          landmarkModel == other.landmarkModel &&
          embeddingDimension == other.embeddingDimension &&
          targetFaceSize == other.targetFaceSize &&
          maxDetectedFaces == other.maxDetectedFaces &&
          logLevel == other.logLevel;

  @override
  int get hashCode => Object.hash(
        detectionThreshold,
        matchingThreshold,
        distanceMetric,
        landmarkModel,
        embeddingDimension,
        targetFaceSize,
        maxDetectedFaces,
        logLevel,
      );

  @override
  String toString() {
    return 'FaceKitConfig(detectionThreshold: $detectionThreshold, '
        'matchingThreshold: $matchingThreshold, metric: $distanceMetric, '
        'landmarks: $landmarkModel, dim: $embeddingDimension, '
        'targetFaceSize: ${targetFaceSize}x$targetFaceSize, maxFaces: $maxDetectedFaces)';
  }
}
