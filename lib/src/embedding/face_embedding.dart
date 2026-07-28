import 'dart:typed_data';
import '../core/facekit_exception.dart';
import '../math/vector.dart';

/// Represents a 128-dimensional facial feature embedding vector.
class FaceEmbedding {
  /// Raw 32-bit floating point embedding buffer.
  final Float32List values;

  /// Dimensionality of embedding vector (default 128).
  int get dimension => values.length;

  /// Creates a [FaceEmbedding] wrapping a [Float32List].
  FaceEmbedding(this.values) {
    if (values.isEmpty) {
      throw const ValidationException('Embedding buffer cannot be empty');
    }
  }

  /// Creates a [FaceEmbedding] from a Dart [List<double>].
  factory FaceEmbedding.fromList(List<double> list) {
    if (list.isEmpty) {
      throw const ValidationException('Embedding input list cannot be empty');
    }
    final floatBuf = Float32List(list.length);
    for (var i = 0; i < list.length; i++) {
      floatBuf[i] = list[i];
    }
    return FaceEmbedding(floatBuf);
  }

  /// Converts this embedding into a FaceKit [Vector].
  Vector toVector() => Vector.fromFloat32List(values);

  /// Computes Cosine Similarity with [other] face embedding (higher is more similar, 1.0 = identical).
  double cosineSimilarity(FaceEmbedding other) {
    return toVector().cosineSimilarity(other.toVector());
  }

  /// Computes Euclidean L2 distance with [other] face embedding (lower is more similar, 0.0 = identical).
  double euclideanDistance(FaceEmbedding other) {
    return toVector().euclideanDistance(other.toVector());
  }

  /// Converts embedding to a standard Dart `List<double>`.
  List<double> toList() => values.toList();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FaceEmbedding || dimension != other.dimension) return false;
    for (var i = 0; i < dimension; i++) {
      if (values[i] != other.values[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(values);

  @override
  String toString() => 'FaceEmbedding(dim: $dimension)';
}
