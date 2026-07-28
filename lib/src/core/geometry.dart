import 'dart:math' as math;
import 'facekit_exception.dart';

/// Pure Dart 2D Rectangle structure representing bounding box boundaries.
class Rect {
  /// Left coordinate (x min).
  final double left;

  /// Top coordinate (y min).
  final double top;

  /// Width of rectangle.
  final double width;

  /// Height of rectangle.
  final double height;

  /// Creates a [Rect] from left, top, width, and height.
  Rect(this.left, this.top, this.width, this.height) {
    if (width < 0 || height < 0) {
      throw const ValidationException(
        'Rect width and height cannot be negative',
      );
    }
  }

  /// Right coordinate (x max).
  double get right => left + width;

  /// Bottom coordinate (y max).
  double get bottom => top + height;

  /// Area of rectangle in square units.
  double get area => width * height;

  /// Center x coordinate.
  double get centerX => left + width / 2.0;

  /// Center y coordinate.
  double get centerY => top + height / 2.0;

  /// Calculates Intersection over Union (IoU) metric with [other] rectangle.
  double computeIoU(Rect other) {
    final interLeft = math.max(left, other.left);
    final interTop = math.max(top, other.top);
    final interRight = math.min(right, other.right);
    final interBottom = math.min(bottom, other.bottom);

    final interW = math.max(0.0, interRight - interLeft);
    final interH = math.max(0.0, interBottom - interTop);
    final interArea = interW * interH;

    if (interArea == 0.0) return 0.0;

    final unionArea = area + other.area - interArea;
    if (unionArea <= 0.0) return 0.0;

    return interArea / unionArea;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rect &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          top == other.top &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() =>
      'Rect(L:${left.toStringAsFixed(1)}, T:${top.toStringAsFixed(1)}, W:${width.toStringAsFixed(1)}, H:${height.toStringAsFixed(1)})';
}
