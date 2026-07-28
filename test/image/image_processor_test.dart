import 'dart:typed_data';
import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('ImageProcessor Tests', () {
    test('bilinear resize scales 2x2 image to 4x4', () {
      final bytes = Uint8List.fromList([
        10, 20,
        30, 40,
      ]);
      final gray = FaceImage.fromGrayscale(bytes, 2, 2);
      final resized = ImageProcessor.resizeBilinear(gray, 4, 4);

      expect(resized.width, equals(4));
      expect(resized.height, equals(4));
      expect(resized.getPixel(0, 0).r, closeTo(10, 5));
      expect(resized.getPixel(3, 3).r, closeTo(40, 5));
    });

    test('crop extracts correct sub-rectangle', () {
      final bytes = Uint8List.fromList([
        1, 2, 3, 4,
        5, 6, 7, 8,
        9, 10, 11, 12,
        13, 14, 15, 16,
      ]);
      final img = FaceImage.fromGrayscale(bytes, 4, 4);
      final cropped = ImageProcessor.crop(img, 1, 1, 2, 2);

      expect(cropped.width, equals(2));
      expect(cropped.height, equals(2));
      expect(cropped.getPixel(0, 0).r, equals(6));
      expect(cropped.getPixel(1, 0).r, equals(7));
      expect(cropped.getPixel(0, 1).r, equals(10));
      expect(cropped.getPixel(1, 1).r, equals(11));
    });

    test('pad adds background border correctly', () {
      final bytes = Uint8List.fromList([255]);
      final img = FaceImage.fromGrayscale(bytes, 1, 1);
      final padded = ImageProcessor.pad(img, 1, 1, 1, 1, fillColor: const Pixel.gray(0));

      expect(padded.width, equals(3));
      expect(padded.height, equals(3));
      expect(padded.getPixel(0, 0).r, equals(0));
      expect(padded.getPixel(1, 1).r, equals(255));
    });

    test('histogram equalization enhances contrast', () {
      final bytes = Uint8List.fromList([
        50, 50,
        50, 200,
      ]);
      final img = FaceImage.fromGrayscale(bytes, 2, 2);
      final eq = ImageProcessor.histogramEqualization(img);

      expect(eq.width, equals(2));
      expect(eq.height, equals(2));
      expect(eq.getPixel(0, 0).r, equals(0));
      expect(eq.getPixel(1, 1).r, equals(255));
    });

    test('gaussian blur applies spatial smoothing', () {
      final bytes = Uint8List.fromList([
        0, 0, 0, 0, 0,
        0, 255, 255, 255, 0,
        0, 255, 255, 255, 0,
        0, 255, 255, 255, 0,
        0, 0, 0, 0, 0,
      ]);
      final img = FaceImage.fromGrayscale(bytes, 5, 5);
      final blurred = ImageProcessor.gaussianBlur(img, kernelSize: 3, sigma: 1.0);

      expect(blurred.width, equals(5));
      expect(blurred.height, equals(5));
      // Corner of high-intensity block (1,1) will blur from 255 down to ~188
      expect(blurred.getPixel(1, 1).r, lessThan(255));
    });

    test('sobel edge detection detects intensity boundaries', () {
      final bytes = Uint8List.fromList([
        0, 0, 255, 255,
        0, 0, 255, 255,
        0, 0, 255, 255,
        0, 0, 255, 255,
      ]);
      final img = FaceImage.fromGrayscale(bytes, 4, 4);
      final sobel = ImageProcessor.sobelEdgeDetection(img);

      expect(sobel.width, equals(4));
      expect(sobel.height, equals(4));
      // Vertical step edge at x=1 to x=2 should yield high Sobel magnitude
      expect(sobel.getPixel(1, 1).r, greaterThan(100));
    });

    test('integral image evaluates O(1) rectangular region sum', () {
      final bytes = Uint8List.fromList([
        1, 2, 3,
        4, 5, 6,
        7, 8, 9,
      ]);
      final img = FaceImage.fromGrayscale(bytes, 3, 3);
      final integral = IntegralImage.fromImage(img);

      // Entire image sum: 1+2+3+4+5+6+7+8+9 = 45
      expect(integral.getSum(0, 0, 2, 2), equals(45));
      // Top-left 2x2 sum: 1+2+4+5 = 12
      expect(integral.getSum(0, 0, 1, 1), equals(12));
      // Center 1x1: 5
      expect(integral.getSum(1, 1, 1, 1), equals(5));
    });

    test('toTensor converts FaceImage to 3D Tensor', () {
      final bytes = Uint8List.fromList([
        255, 0, 0,
        0, 255, 0,
      ]);
      final img = FaceImage.fromRgb(bytes, 2, 1);
      final tensor = ImageProcessor.toTensor(img, normalizeZeroToOne: true);

      expect(tensor.shape, equals([3, 1, 2]));
      expect(tensor.get3D(0, 0, 0), equals(1.0)); // Red channel at (0,0)
      expect(tensor.get3D(1, 0, 0), equals(0.0)); // Green channel at (0,0)
    });
  });
}
