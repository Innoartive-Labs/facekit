import 'dart:math' as math;
import '../core/facekit_config.dart';
import '../core/facekit_exception.dart';
import '../detector/face.dart';
import '../image/face_image.dart';
import '../image/image_processor.dart';
import '../landmarks/face_landmark.dart';

/// Pure Dart facial similarity transformer and aligner producing normalized 112x112 canonical face images.
class FaceAligner {
  /// Active configuration.
  final FaceKitConfig config;

  /// Target side dimension (112x112).
  final int targetSize;

  /// Target eye distance in 112x112 space (36 pixels).
  static const double targetEyeDist = 36.0;

  /// Target eye y-level in 112x112 space (48 pixels).
  static const double targetEyeY = 48.0;

  /// Creates a [FaceAligner].
  FaceAligner({FaceKitConfig? config})
      : config = config ?? FaceKitConfig.defaultConfig,
        targetSize = (config ?? FaceKitConfig.defaultConfig).targetFaceSize;

  /// Aligns, levels eyes, scales, and crops the detected [face] into a normalized 112x112 [FaceImage].
  FaceImage alignFace(FaceImage image, Face face, List<FaceLandmark> landmarks) {
    if (landmarks.length < 48) {
      throw ValidationException('Face alignment requires at least 48 landmark points, got ${landmarks.length}');
    }

    // 1. Compute right eye (points 36..41) and left eye (points 42..47) centers
    double rEyeX = 0.0, rEyeY = 0.0;
    for (var i = 36; i <= 41; i++) {
      rEyeX += landmarks[i].x;
      rEyeY += landmarks[i].y;
    }
    rEyeX /= 6.0;
    rEyeY /= 6.0;

    double lEyeX = 0.0, lEyeY = 0.0;
    for (var i = 42; i <= 47; i++) {
      lEyeX += landmarks[i].x;
      lEyeY += landmarks[i].y;
    }
    lEyeX /= 6.0;
    lEyeY /= 6.0;

    // 2. Compute head roll angle and inter-ocular distance
    final dX = lEyeX - rEyeX;
    final dY = lEyeY - rEyeY;
    final angleRad = math.atan2(dY, dX);

    final currentEyeDist = math.sqrt(dX * dX + dY * dY);

    // 3. Rotate image to level eyes horizontally
    final rotatedImg = ImageProcessor.rotate(image, angleRad);

    // 4. Compute scale factor to match 36px eye distance in 112x112 crop
    final scale = targetEyeDist / math.max(currentEyeDist, 1.0);
    final scaledW = (rotatedImg.width * scale).round();
    final scaledH = (rotatedImg.height * scale).round();

    if (scaledW <= 0 || scaledH <= 0) {
      throw const ValidationException('Calculated face scale resulted in invalid dimensions');
    }

    final scaledImg = ImageProcessor.resizeBilinear(rotatedImg, scaledW, scaledH);

    // 5. Center crop 112x112 around eye midpoint
    final eyeMidX = (rEyeX + lEyeX) / 2.0 * scale;
    final eyeMidY = (rEyeY + lEyeY) / 2.0 * scale;

    final targetMidX = targetSize / 2.0;
    const targetMidY = targetEyeY;

    var cropX = (eyeMidX - targetMidX).round();
    var cropY = (eyeMidY - targetMidY).round();

    cropX = cropX.clamp(0, math.max(0, scaledImg.width - targetSize));
    cropY = cropY.clamp(0, math.max(0, scaledImg.height - targetSize));

    final actualCropW = math.min(targetSize, scaledImg.width - cropX);
    final actualCropH = math.min(targetSize, scaledImg.height - cropY);

    final cropped = ImageProcessor.crop(scaledImg, cropX, cropY, actualCropW, actualCropH);

    // Pad if crop edge reached image boundary
    if (cropped.width < targetSize || cropped.height < targetSize) {
      final padRight = targetSize - cropped.width;
      final padBottom = targetSize - cropped.height;
      return ImageProcessor.pad(cropped, 0, padBottom, 0, padRight);
    }

    return cropped;
  }
}
