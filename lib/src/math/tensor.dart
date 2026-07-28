import 'dart:typed_data';
import '../core/facekit_exception.dart';

/// Multi-dimensional tensor backed by a contiguous [Float32List] buffer and stride calculations.
class Tensor {
  /// Dimension sizes of the tensor (e.g. [Channels, Height, Width] or [Batch, Channels, Height, Width]).
  final List<int> shape;

  /// Stride offsets for each dimension.
  final List<int> strides;

  /// Total number of elements in the tensor.
  final int size;

  /// Contiguous 32-bit floating point data buffer.
  final Float32List data;

  /// Creates a zero-initialized [Tensor] with the given [shape].
  Tensor(this.shape)
      : strides = _computeStrides(shape),
        size = _computeSize(shape),
        data = Float32List(_computeSize(shape)) {
    if (shape.isEmpty) {
      throw const ValidationException('Tensor shape cannot be empty');
    }
  }

  /// Creates a [Tensor] wrapping a flat [Float32List] buffer.
  Tensor.fromFloat32List(this.shape, this.data)
      : strides = _computeStrides(shape),
        size = _computeSize(shape) {
    if (shape.isEmpty) {
      throw const ValidationException('Tensor shape cannot be empty');
    }
    if (data.length != size) {
      throw ValidationException(
        'Tensor data length (${data.length}) does not match shape size ($size for shape $shape)',
      );
    }
  }

  static int _computeSize(List<int> shape) {
    var total = 1;
    for (final dim in shape) {
      if (dim <= 0) {
        throw ValidationException('Tensor shape dimensions must be positive: $shape');
      }
      total *= dim;
    }
    return total;
  }

  static List<int> _computeStrides(List<int> shape) {
    final rank = shape.length;
    final strides = List<int>.filled(rank, 1);
    var stride = 1;
    for (var i = rank - 1; i >= 0; i--) {
      strides[i] = stride;
      stride *= shape[i];
    }
    return strides;
  }

  /// Computes flat 1D buffer index from multi-dimensional [indices].
  int getFlatIndex(List<int> indices) {
    if (indices.length != shape.length) {
      throw ValidationException('Index rank (${indices.length}) does not match tensor rank (${shape.length})');
    }
    var flatIndex = 0;
    for (var i = 0; i < indices.length; i++) {
      final idx = indices[i];
      if (idx < 0 || idx >= shape[i]) {
        throw ValidationException('Index $idx out of bounds for dimension $i (size ${shape[i]})');
      }
      flatIndex += idx * strides[i];
    }
    return flatIndex;
  }

  /// Returns the value at multi-dimensional [indices].
  double get(List<int> indices) => data[getFlatIndex(indices)];

  /// Sets the value at multi-dimensional [indices].
  void set(List<int> indices, double value) => data[getFlatIndex(indices)] = value;

  /// Fast accessor for 3D tensor: `[c, h, w]`.
  double get3D(int c, int h, int w) {
    return data[c * strides[0] + h * strides[1] + w];
  }

  /// Fast setter for 3D tensor: `[c, h, w]`.
  void set3D(int c, int h, int w, double val) {
    data[c * strides[0] + h * strides[1] + w] = val;
  }

  /// Fast accessor for 4D tensor: `[b, c, h, w]`.
  double get4D(int b, int c, int h, int w) {
    return data[b * strides[0] + c * strides[1] + h * strides[2] + w];
  }

  /// Fast setter for 4D tensor: `[b, c, h, w]`.
  void set4D(int b, int c, int h, int w, double val) {
    data[b * strides[0] + c * strides[1] + h * strides[2] + w] = val;
  }

  /// Returns a new [Tensor] sharing the same data buffer with a new [newShape].
  Tensor reshape(List<int> newShape) {
    final newSize = _computeSize(newShape);
    if (newSize != size) {
      throw ValidationException('Cannot reshape tensor of size $size into size $newSize');
    }
    return Tensor.fromFloat32List(newShape, data);
  }

  /// Creates a deep copy of this tensor.
  Tensor clone() {
    final clonedBuf = Float32List.fromList(data);
    return Tensor.fromFloat32List(List<int>.from(shape), clonedBuf);
  }

  @override
  String toString() => 'Tensor(shape: $shape, elements: $size)';
}
