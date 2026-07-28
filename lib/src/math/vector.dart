import 'dart:math' as math;
import 'dart:typed_data';
import '../core/facekit_exception.dart';

/// High-performance 1D math vector backed by a contiguous [Float32List].
class Vector {
  /// Raw underlying 32-bit floating point data buffer.
  final Float32List data;

  /// Dimensionality (number of elements) in the vector.
  final int length;

  /// Creates a zero-initialized [Vector] of specified [length].
  Vector(this.length) : data = Float32List(length) {
    if (length <= 0) {
      throw const ValidationException('Vector length must be positive');
    }
  }

  /// Creates a [Vector] wrapping or copying a [Float32List].
  Vector.fromFloat32List(this.data) : length = data.length {
    if (data.isEmpty) {
      throw const ValidationException('Vector data buffer cannot be empty');
    }
  }

  /// Creates a [Vector] from a standard Dart [List<double>].
  factory Vector.fromList(List<double> list) {
    if (list.isEmpty) {
      throw const ValidationException('Vector input list cannot be empty');
    }
    final floatList = Float32List(list.length);
    for (var i = 0; i < list.length; i++) {
      floatList[i] = list[i];
    }
    return Vector.fromFloat32List(floatList);
  }

  /// Accesses the vector value at element index [i].
  double operator [](int i) => data[i];

  /// Sets the vector value at element index [i].
  void operator []=(int i, double value) => data[i] = value;

  /// Computes the dot product between this vector and [other].
  double dot(Vector other) {
    if (length != other.length) {
      throw ValidationException(
        'Vector dimensions must match for dot product ($length vs ${other.length})',
      );
    }
    double sum = 0.0;
    final a = data;
    final b = other.data;

    // Loop unrolling for 4-element SIMD-friendly processing
    final mainLoopEnd = length & ~3;
    var i = 0;
    for (; i < mainLoopEnd; i += 4) {
      sum +=
          a[i] * b[i] +
          a[i + 1] * b[i + 1] +
          a[i + 2] * b[i + 2] +
          a[i + 3] * b[i + 3];
    }
    for (; i < length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  /// Computes the Euclidean L2 norm (magnitude) of this vector.
  double norm() {
    return math.sqrt(dot(this));
  }

  /// Returns a new L2-normalized unit [Vector].
  Vector normalize() {
    final mag = norm();
    if (mag <= 1e-12 || mag.isNaN) {
      final res = Vector(length);
      res.data[0] = 1.0;
      return res;
    }
    final result = Vector(length);
    final invMag = 1.0 / mag;
    for (var i = 0; i < length; i++) {
      result.data[i] = data[i] * invMag;
    }
    return result;
  }

  /// Vector addition (element-wise).
  Vector add(Vector other) {
    if (length != other.length) {
      throw ValidationException(
        'Vector dimensions must match for addition ($length vs ${other.length})',
      );
    }
    final result = Vector(length);
    final a = data;
    final b = other.data;
    for (var i = 0; i < length; i++) {
      result.data[i] = a[i] + b[i];
    }
    return result;
  }

  /// Vector subtraction (element-wise).
  Vector subtract(Vector other) {
    if (length != other.length) {
      throw ValidationException(
        'Vector dimensions must match for subtraction ($length vs ${other.length})',
      );
    }
    final result = Vector(length);
    final a = data;
    final b = other.data;
    for (var i = 0; i < length; i++) {
      result.data[i] = a[i] - b[i];
    }
    return result;
  }

  /// Multiplies all elements by a scalar value.
  Vector scale(double scalar) {
    final result = Vector(length);
    for (var i = 0; i < length; i++) {
      result.data[i] = data[i] * scalar;
    }
    return result;
  }

  /// Computes the Cosine Similarity metric between this vector and [other].
  /// Score ranges from -1.0 to 1.0 (1.0 = identical direction).
  double cosineSimilarity(Vector other) {
    final dotProduct = dot(other);
    final normA = norm();
    final normB = other.norm();
    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }
    final sim = dotProduct / (normA * normB);
    return sim.clamp(-1.0, 1.0);
  }

  /// Computes the Euclidean L2 distance between this vector and [other].
  double euclideanDistance(Vector other) {
    if (length != other.length) {
      throw ValidationException(
        'Vector dimensions must match for Euclidean distance ($length vs ${other.length})',
      );
    }
    double sum = 0.0;
    final a = data;
    final b = other.data;
    for (var i = 0; i < length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return math.sqrt(sum);
  }

  /// Creates a deep copy of this vector.
  Vector clone() {
    final copied = Float32List.fromList(data);
    return Vector.fromFloat32List(copied);
  }

  @override
  String toString() => 'Vector(length: $length)';
}
