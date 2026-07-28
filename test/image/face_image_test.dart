import 'dart:typed_data';
import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('FaceImage Tests', () {
    test('creates RGB FaceImage successfully', () {
      final bytes = Uint8List.fromList([
        255, 0, 0, // pixel (0,0) red
        0, 255, 0, // pixel (1,0) green
        0, 0, 255, // pixel (0,1) blue
        255, 255, 255, // pixel (1,1) white
      ]);
      final img = FaceImage.fromRgb(bytes, 2, 2);

      expect(img.width, equals(2));
      expect(img.height, equals(2));
      expect(img.format, equals(ImageFormat.rgb));
      expect(img.channels, equals(3));
      expect(img.rowStride, equals(6));

      final p00 = img.getPixel(0, 0);
      expect(p00.r, equals(255));
      expect(p00.g, equals(0));
      expect(p00.b, equals(0));

      final p11 = img.getPixel(1, 1);
      expect(p11.r, equals(255));
      expect(p11.g, equals(255));
      expect(p11.b, equals(255));
    });

    test('throws InvalidImageException on insufficient buffer', () {
      final invalidBytes = Uint8List(5); // needs 2x2x3 = 12 bytes
      expect(
        () => FaceImage.fromRgb(invalidBytes, 2, 2),
        throwsA(isA<InvalidImageException>()),
      );
    });

    test('converts RGB to Grayscale correctly', () {
      final bytes = Uint8List.fromList([
        255, 0, 0, // pure red
        0, 255, 0, // pure green
        0, 0, 255, // pure blue
        100, 100, 100, // gray
      ]);
      final rgbImg = FaceImage.fromRgb(bytes, 2, 2);
      final grayImg = rgbImg.toGrayscale();

      expect(grayImg.format, equals(ImageFormat.grayscale));
      expect(grayImg.channels, equals(1));
      expect(grayImg.buffer.length, equals(4));

      final p00 = grayImg.getPixel(0, 0);
      // Red 255 -> 0.299 * 255 = 76
      expect(p00.r, closeTo(74, 5));
    });

    test('converts Grayscale to RGB correctly', () {
      final bytes = Uint8List.fromList([100, 200]);
      final grayImg = FaceImage.fromGrayscale(bytes, 2, 1);
      final rgbImg = grayImg.toRgb();

      expect(rgbImg.format, equals(ImageFormat.rgb));
      expect(rgbImg.channels, equals(3));
      final p0 = rgbImg.getPixel(0, 0);
      expect(p0.r, equals(100));
      expect(p0.g, equals(100));
      expect(p0.b, equals(100));
    });

    test('clone creates a deep copy', () {
      final bytes = Uint8List.fromList([10, 20, 30]);
      final img = FaceImage.fromGrayscale(bytes, 3, 1);
      final cloned = img.clone();

      cloned.setPixel(0, 0, const Pixel.gray(99));
      expect(img.getPixel(0, 0).r, equals(10));
      expect(cloned.getPixel(0, 0).r, equals(99));
    });
  });
}
