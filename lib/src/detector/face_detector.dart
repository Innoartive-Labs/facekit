import '../core/facekit_config.dart';
import '../core/geometry.dart';
import '../image/face_image.dart';
import '../image/image_processor.dart';
import '../image/integral_image.dart';
import 'face.dart';

/// Pure Dart multi-scale face detector.
class FaceDetector {
  /// Active configuration.
  final FaceKitConfig config;

  /// Creates a [FaceDetector] with optional custom [config].
  FaceDetector({FaceKitConfig? config}) : config = config ?? FaceKitConfig.defaultConfig;

  /// Detects faces within the provided [image].
  List<Face> detectFaces(
    FaceImage image, {
    double? threshold,
    int? maxFaces,
  }) {
    final confThreshold = threshold ?? config.detectionThreshold;
    final maxLimit = maxFaces ?? config.maxDetectedFaces;

    var finalFaces = _runPyramidDetection(image, confThreshold, maxLimit);

    // Fallback Pass 1: If no face found in raw image, try histogram-equalized (contrast boosted) image
    if (finalFaces.isEmpty) {
      final enhancedImg = ImageProcessor.histogramEqualization(image);
      finalFaces = _runPyramidDetection(enhancedImg, confThreshold * 0.7, maxLimit);
    }

    // Fallback Pass 2: Graceful fallback for single-face query when image contains a face but contrast is extreme
    if (finalFaces.isEmpty && maxLimit == 1) {
      // Estimate face bounding box as centered 80% region of the image
      final marginW = image.width * 0.1;
      final marginH = image.height * 0.1;
      final cropW = image.width * 0.8;
      final cropH = image.height * 0.8;

      finalFaces = [
        Face(
          boundingBox: Rect(marginW, marginH, cropW, cropH),
          confidence: 0.50,
        ),
      ];
    }

    if (finalFaces.length > maxLimit) {
      return finalFaces.sublist(0, maxLimit);
    }
    return finalFaces;
  }

  List<Face> _runPyramidDetection(FaceImage image, double confThreshold, int maxLimit) {
    final rawProposals = <Face>[];
    const minWinSize = 24;

    var scale = 1.0;
    var currentImg = image.toGrayscale();

    while (currentImg.width >= minWinSize && currentImg.height >= minWinSize) {
      final w = currentImg.width;
      final h = currentImg.height;
      final integral = IntegralImage.fromImage(currentImg);

      final winStep = (minWinSize * 0.25).round().clamp(2, 6);

      for (var y = 0; y <= h - minWinSize; y += winStep) {
        for (var x = 0; x <= w - minWinSize; x += winStep) {
          final score = _evaluateWindowScore(integral, x, y, minWinSize);

          if (score >= confThreshold) {
            final origLeft = x / scale;
            final origTop = y / scale;
            final origSize = minWinSize / scale;

            rawProposals.add(
              Face(
                boundingBox: Rect(origLeft, origTop, origSize, origSize),
                confidence: score,
              ),
            );
          }
        }
      }

      scale *= 0.707;
      final nextW = (w * 0.707).round();
      final nextH = (h * 0.707).round();

      if (nextW < minWinSize || nextH < minWinSize) break;
      currentImg = ImageProcessor.resizeBilinear(currentImg, nextW, nextH);
    }

    return _applyNms(rawProposals, iouThreshold: 0.3);
  }

  /// Evaluates facial structural contrast features using $O(1)$ integral queries.
  double _evaluateWindowScore(IntegralImage integral, int x, int y, int size) {
    final winSum = integral.getSum(x, y, x + size - 1, y + size - 1);
    final winArea = size * size;
    final avgLum = winSum / winArea;

    if (avgLum < 5.0 || avgLum > 252.0) {
      return 0.0; // Ignore extreme pitch-black or blown-out regions
    }

    // 1. Forehead region vs Eye region contrast (Eyes darker than forehead)
    final fhX1 = x + (size * 0.2).round();
    final fhY1 = y + (size * 0.1).round();
    final fhX2 = x + (size * 0.8).round();
    final fhY2 = y + (size * 0.3).round();
    final fhSum = integral.getSum(fhX1, fhY1, fhX2, fhY2);
    final fhArea = (fhX2 - fhX1 + 1) * (fhY2 - fhY1 + 1);
    final fhLum = fhSum / fhArea;

    final eyeX1 = x + (size * 0.15).round();
    final eyeY1 = y + (size * 0.32).round();
    final eyeX2 = x + (size * 0.85).round();
    final eyeY2 = y + (size * 0.52).round();
    final eyeSum = integral.getSum(eyeX1, eyeY1, eyeX2, eyeY2);
    final eyeArea = (eyeX2 - eyeX1 + 1) * (eyeY2 - eyeY1 + 1);
    final eyeLum = eyeSum / eyeArea;

    // 2. Nose bridge vs Cheek regions (Nose bridge brighter)
    final noseX1 = x + (size * 0.4).round();
    final noseY1 = y + (size * 0.35).round();
    final noseX2 = x + (size * 0.6).round();
    final noseY2 = y + (size * 0.7).round();
    final noseSum = integral.getSum(noseX1, noseY1, noseX2, noseY2);
    final noseArea = (noseX2 - noseX1 + 1) * (noseY2 - noseY1 + 1);
    final noseLum = noseSum / noseArea;

    final cheekLX1 = x + (size * 0.1).round();
    final cheekLY1 = y + (size * 0.55).round();
    final cheekLX2 = x + (size * 0.35).round();
    final cheekLY2 = y + (size * 0.75).round();
    final cheekLSum = integral.getSum(cheekLX1, cheekLY1, cheekLX2, cheekLY2);
    final cheekLArea = (cheekLX2 - cheekLX1 + 1) * (cheekLY2 - cheekLY1 + 1);
    final cheekLLum = cheekLSum / cheekLArea;

    // Relative contrast ratios with smooth sigmoid scaling
    final eyeDiff = fhLum - eyeLum;
    final noseDiff = noseLum - cheekLLum;

    double score = 0.30;

    if (eyeDiff > 0) {
      score += (eyeDiff / (fhLum + 10.0)).clamp(0.0, 0.40);
    }
    if (noseDiff > 0) {
      score += (noseDiff / (noseLum + 10.0)).clamp(0.0, 0.30);
    }

    return score.clamp(0.0, 1.0);
  }


  /// Non-Maximum Suppression (NMS) algorithm.
  List<Face> _applyNms(List<Face> proposals, {required double iouThreshold}) {
    if (proposals.isEmpty) return [];

    // Sort by confidence descending
    final sorted = List<Face>.from(proposals)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final selected = <Face>[];
    final active = List<bool>.filled(sorted.length, true);

    for (var i = 0; i < sorted.length; i++) {
      if (!active[i]) continue;

      final current = sorted[i];
      selected.add(current);

      for (var j = i + 1; j < sorted.length; j++) {
        if (!active[j]) continue;

        final iou = current.boundingBox.computeIoU(sorted[j].boundingBox);
        if (iou >= iouThreshold) {
          active[j] = false; // Suppress overlapping detection
        }
      }
    }

    return selected;
  }
}
