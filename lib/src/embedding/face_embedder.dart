import '../core/facekit_config.dart';
import '../core/facekit_exception.dart';
import '../image/face_image.dart';
import '../image/image_processor.dart';
import '../math/vector.dart';
import 'face_embedding.dart';

/// Pure Dart 128-dimensional discriminative face feature extractor.
class FaceEmbedder {
  /// Active configuration.
  final FaceKitConfig config;

  /// Dimensionality of output embedding (128).
  final int embeddingDim;

  /// Creates a [FaceEmbedder].
  FaceEmbedder({FaceKitConfig? config})
      : config = config ?? FaceKitConfig.defaultConfig,
        embeddingDim = (config ?? FaceKitConfig.defaultConfig).embeddingDimension;

  /// Extracts a 128-dimensional L2-normalized feature embedding from a 112x112 aligned [faceImage].
  FaceEmbedding extractEmbedding(FaceImage faceImage) {
    if (faceImage.width != config.targetFaceSize || faceImage.height != config.targetFaceSize) {
      throw ValidationException(
        'FaceEmbedder requires aligned ${config.targetFaceSize}x${config.targetFaceSize} image, got ${faceImage.width}x${faceImage.height}',
      );
    }

    // 1. Extract 128D spatial grid LBP & HOG feature vector
    final rawFeatures = ImageProcessor.computeSpatialFeatureVector(faceImage);
    final inputVec = Vector.fromList(rawFeatures);

    // 2. L2 unit normalization
    final normalized = inputVec.normalize();

    return FaceEmbedding(normalized.data);
  }
}


