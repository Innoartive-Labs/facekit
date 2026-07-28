/// Represents a single facial landmark point (2D or 3D).
class FaceLandmark {
  /// Index of the landmark in the landmark model array (0 to 67 for 68-point model).
  final int index;

  /// X coordinate in image pixel space.
  final double x;

  /// Y coordinate in image pixel space.
  final double y;

  /// Optional Z (depth) coordinate for 3D mesh points.
  final double? z;

  /// Creates a [FaceLandmark] point.
  const FaceLandmark({
    required this.index,
    required this.x,
    required this.y,
    this.z,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaceLandmark &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          x == other.x &&
          y == other.y &&
          z == other.z;

  @override
  int get hashCode => Object.hash(index, x, y, z);

  @override
  String toString() => 'Landmark#$index(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}
