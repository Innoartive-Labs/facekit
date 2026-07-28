import 'dart:typed_data';
import '../core/facekit_exception.dart';
import 'face_image.dart';

/// 2D Integral Image (Summed Area Table) for $O(1)$ box query evaluations.
class IntegralImage {
  /// Width of original image.
  final int width;

  /// Height of original image.
  final int height;

  /// 32-bit integer sum matrix of size `(width + 1) * (height + 1)`.
  final Int32List _sumTable;

  /// Creates an [IntegralImage] from a grayscale [FaceImage].
  factory IntegralImage.fromImage(FaceImage image) {
    final gray = image.format == ImageFormat.grayscale ? image : image.toGrayscale();
    final w = gray.width;
    final h = gray.height;
    final tableWidth = w + 1;
    final tableHeight = h + 1;
    final table = Int32List(tableWidth * tableHeight);

    final buf = gray.buffer;

    for (var y = 0; y < h; y++) {
      int rowSum = 0;
      final srcRowOff = y * w;
      final dstRowOff = (y + 1) * tableWidth;
      final prevDstRowOff = y * tableWidth;

      for (var x = 0; x < w; x++) {
        rowSum += buf[srcRowOff + x];
        table[dstRowOff + (x + 1)] = table[prevDstRowOff + (x + 1)] + rowSum;
      }
    }

    return IntegralImage._(w, h, table);
  }

  IntegralImage._(this.width, this.height, this._sumTable);

  /// Evaluates the total sum of pixel values within rectangle [x1, y1] to [x2, y2] (inclusive) in $O(1)$ time.
  int getSum(int x1, int y1, int x2, int y2) {
    if (x1 < 0 || y1 < 0 || x2 >= width || y2 >= height || x1 > x2 || y1 > y2) {
      throw ValidationException('Invalid integral rectangle bounds: ($x1,$y1) to ($x2,$y2) on ${width}x$height image');
    }
    final tw = width + 1;
    final rx2 = x2 + 1;
    final ry2 = y2 + 1;
    final rx1 = x1;
    final ry1 = y1;

    final a = _sumTable[ry2 * tw + rx2];
    final b = _sumTable[ry1 * tw + rx2];
    final c = _sumTable[ry2 * tw + rx1];
    final d = _sumTable[ry1 * tw + rx1];

    return a - b - c + d;
  }
}
