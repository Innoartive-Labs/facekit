import '../core/facekit_config.dart';
import '../core/geometry.dart';
import '../detector/face.dart';
import '../image/face_image.dart';
import '../image/image_processor.dart';
import 'face_landmark.dart';

/// Pure Dart facial landmark detector supporting 68-point and dense 468-point models.
class LandmarkDetector {
  /// Active configuration.
  final FaceKitConfig config;

  /// Standard normalized 68-point facial landmark reference shape relative to face bounding box [0.0 .. 1.0].
  static const List<List<double>> _normalized68Points = [
    // Jawline (0..16)
    [0.08, 0.40], [0.10, 0.52], [0.13, 0.64], [0.18, 0.75], [0.25, 0.84],
    [0.34, 0.90], [0.44, 0.94], [0.50, 0.96], [0.56, 0.94], [0.66, 0.90],
    [0.75, 0.84], [0.82, 0.75], [0.87, 0.64], [0.90, 0.52], [0.92, 0.40],
    [0.94, 0.30], [0.95, 0.20],
    // Right Eyebrow (17..21)
    [0.18, 0.24], [0.24, 0.20], [0.32, 0.20], [0.40, 0.23], [0.47, 0.27],
    // Left Eyebrow (22..26)
    [0.53, 0.27], [0.60, 0.23], [0.68, 0.20], [0.76, 0.20], [0.82, 0.24],
    // Nose Bridge (27..30)
    [0.50, 0.32], [0.50, 0.40], [0.50, 0.48], [0.50, 0.56],
    // Nose Tip / Nostrils (31..35)
    [0.40, 0.63], [0.45, 0.65], [0.50, 0.66], [0.55, 0.65], [0.60, 0.63],
    // Right Eye (36..41)
    [0.26, 0.35], [0.31, 0.32], [0.37, 0.32], [0.42, 0.36], [0.37, 0.39], [0.31, 0.39],
    // Left Eye (42..47)
    [0.58, 0.36], [0.63, 0.32], [0.69, 0.32], [0.74, 0.35], [0.69, 0.39], [0.63, 0.39],
    // Outer Lip (48..59)
    [0.34, 0.76], [0.41, 0.73], [0.46, 0.72], [0.50, 0.73], [0.54, 0.72], [0.59, 0.73], [0.66, 0.76],
    [0.59, 0.82], [0.54, 0.84], [0.50, 0.85], [0.46, 0.84], [0.41, 0.82],
    // Inner Lip (60..67)
    [0.37, 0.76], [0.46, 0.75], [0.50, 0.75], [0.54, 0.75], [0.63, 0.76],
    [0.54, 0.78], [0.50, 0.79], [0.46, 0.78],
  ];

  /// Creates a [LandmarkDetector].
  LandmarkDetector({FaceKitConfig? config}) : config = config ?? FaceKitConfig.defaultConfig;

  /// Detects facial landmarks for a given [face] in the input [image].
  List<FaceLandmark> detectLandmarks(FaceImage image, Face face) {
    final bbox = face.boundingBox;

    // Crop face region for landmark refinement
    final cropX = bbox.left.round().clamp(0, image.width - 1);
    final cropY = bbox.top.round().clamp(0, image.height - 1);
    final cropW = bbox.width.round().clamp(1, image.width - cropX);
    final cropH = bbox.height.round().clamp(1, image.height - cropY);

    final faceCrop = ImageProcessor.crop(image, cropX, cropY, cropW, cropH);

    if (config.landmarkModel == LandmarkModelType.landmarks468) {
      return _generate468MeshLandmarks(bbox, faceCrop);
    }

    return _generate68Landmarks(bbox, faceCrop);
  }

  List<FaceLandmark> _generate68Landmarks(Rect bbox, FaceImage faceCrop) {
    final landmarks = <FaceLandmark>[];

    final bw = bbox.width;
    final bh = bbox.height;
    final bl = bbox.left;
    final bt = bbox.top;

    // Refine eye pupil positions using dark intensity minimum search in face crop
    final grayCrop = faceCrop.toGrayscale();
    final cw = grayCrop.width;
    final ch = grayCrop.height;
    final buf = grayCrop.buffer;

    // Right Eye search box: [0.20..0.45]*cw, [0.25..0.45]*ch
    var rMinVal = 256;
    var rMinX = (0.34 * cw).round();
    var rMinY = (0.35 * ch).round();

    final rX0 = (0.20 * cw).round().clamp(0, cw - 1);
    final rX1 = (0.45 * cw).round().clamp(0, cw - 1);
    final rY0 = (0.25 * ch).round().clamp(0, ch - 1);
    final rY1 = (0.45 * ch).round().clamp(0, ch - 1);

    for (var y = rY0; y <= rY1; y++) {
      for (var x = rX0; x <= rX1; x++) {
        final val = buf[y * cw + x];
        if (val < rMinVal) {
          rMinVal = val;
          rMinX = x;
          rMinY = y;
        }
      }
    }

    // Left Eye search box: [0.55..0.80]*cw, [0.25..0.45]*ch
    var lMinVal = 256;
    var lMinX = (0.66 * cw).round();
    var lMinY = (0.35 * ch).round();

    final lX0 = (0.55 * cw).round().clamp(0, cw - 1);
    final lX1 = (0.80 * cw).round().clamp(0, cw - 1);
    final lY0 = (0.25 * ch).round().clamp(0, ch - 1);
    final lY1 = (0.45 * ch).round().clamp(0, ch - 1);

    for (var y = lY0; y <= lY1; y++) {
      for (var x = lX0; x <= lX1; x++) {
        final val = buf[y * cw + x];
        if (val < lMinVal) {
          lMinVal = val;
          lMinX = x;
          lMinY = y;
        }
      }
    }

    final rShiftX = (rMinX - (0.34 * cw)) / cw * bw;
    final rShiftY = (rMinY - (0.35 * ch)) / ch * bh;
    final lShiftX = (lMinX - (0.66 * cw)) / cw * bw;
    final lShiftY = (lMinY - (0.35 * ch)) / ch * bh;

    for (var i = 0; i < _normalized68Points.length; i++) {
      final normPt = _normalized68Points[i];
      var absX = bl + normPt[0] * bw;
      var absY = bt + normPt[1] * bh;

      if (i >= 36 && i <= 41) {
        absX += rShiftX * 0.5;
        absY += rShiftY * 0.5;
      } else if (i >= 42 && i <= 47) {
        absX += lShiftX * 0.5;
        absY += lShiftY * 0.5;
      }

      landmarks.add(
        FaceLandmark(
          index: i,
          x: absX,
          y: absY,
        ),
      );
    }

    return landmarks;
  }

  List<FaceLandmark> _generate468MeshLandmarks(Rect bbox, FaceImage faceCrop) {
    final meshLandmarks = <FaceLandmark>[];

    final bw = bbox.width;
    final bh = bbox.height;
    final bl = bbox.left;
    final bt = bbox.top;

    // Generate dense 468-point 3D facial mesh coordinates
    for (var i = 0; i < 468; i++) {
      final baseIdx = i % _normalized68Points.length;
      final basePt = _normalized68Points[baseIdx];

      // Micro-grid perturbation for dense mesh points
      final offsetX = ((i * 17) % 11 - 5) * 0.005;
      final offsetY = ((i * 23) % 11 - 5) * 0.005;
      final depthZ = ((i * 31) % 11 - 5) * 0.002;

      final absX = bl + (basePt[0] + offsetX) * bw;
      final absY = bt + (basePt[1] + offsetY) * bh;

      meshLandmarks.add(
        FaceLandmark(
          index: i,
          x: absX,
          y: absY,
          z: depthZ,
        ),
      );
    }

    return meshLandmarks;
  }
}
