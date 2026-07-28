import 'dart:typed_data';
import '../core/geometry.dart';

/// Represents a detected face instance with bounding box, confidence, landmarks, and feature embedding.
class Face {
  /// Bounding box location of face in original image space.
  final Rect boundingBox;

  /// Detection confidence score (0.0 to 1.0).
  final double confidence;

  /// Optional facial landmarks (68 or 468 points).
  final List<dynamic>? landmarks;

  /// Optional 128-dimensional feature embedding vector.
  final Float32List? embedding;

  /// Creates a [Face] entity.
  const Face({
    required this.boundingBox,
    required this.confidence,
    this.landmarks,
    this.embedding,
  });

  /// Returns a copy of [Face] with updated attributes.
  Face copyWith({
    Rect? boundingBox,
    double? confidence,
    List<dynamic>? landmarks,
    Float32List? embedding,
  }) {
    return Face(
      boundingBox: boundingBox ?? this.boundingBox,
      confidence: confidence ?? this.confidence,
      landmarks: landmarks ?? this.landmarks,
      embedding: embedding ?? this.embedding,
    );
  }

  @override
  String toString() => 'Face(bbox: $boundingBox, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}
