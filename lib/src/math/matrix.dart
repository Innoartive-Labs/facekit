import 'dart:typed_data';
import '../core/facekit_exception.dart';
import 'vector.dart';

/// High-performance 2D Matrix backed by a flat contiguous [Float32List].
class Matrix {
  /// Number of rows.
  final int rows;

  /// Number of columns.
  final int cols;

  /// Flat contiguous row-major memory buffer storing matrix entries.
  final Float32List data;

  /// Creates a zero-initialized [Matrix] of dimension [rows] x [cols].
  Matrix(this.rows, this.cols) : data = Float32List(rows * cols) {
    if (rows <= 0 || cols <= 0) {
      throw ValidationException('Matrix dimensions must be positive ($rows x $cols)');
    }
  }

  /// Creates a [Matrix] wrapping a flat [Float32List] buffer.
  Matrix.fromFloat32List(this.rows, this.cols, this.data) {
    if (rows <= 0 || cols <= 0) {
      throw ValidationException('Matrix dimensions must be positive ($rows x $cols)');
    }
    if (data.length != rows * cols) {
      throw ValidationException(
        'Matrix buffer length (${data.length}) does not match expected size (${rows * cols})',
      );
    }
  }

  /// Creates a [Matrix] from a 2D Dart [List<List<double>>].
  factory Matrix.fromRows(List<List<double>> rowsList) {
    if (rowsList.isEmpty || rowsList.first.isEmpty) {
      throw const ValidationException('Input 2D row list cannot be empty');
    }
    final r = rowsList.length;
    final c = rowsList.first.length;
    final floatData = Float32List(r * c);
    var idx = 0;
    for (var i = 0; i < r; i++) {
      if (rowsList[i].length != c) {
        throw ValidationException('Inconsistent column count at row $i');
      }
      for (var j = 0; j < c; j++) {
        floatData[idx++] = rowsList[i][j];
      }
    }
    return Matrix.fromFloat32List(r, c, floatData);
  }

  /// Creates an identity matrix of size [n] x [n].
  factory Matrix.identity(int n) {
    final mat = Matrix(n, n);
    for (var i = 0; i < n; i++) {
      mat.set(i, i, 1.0);
    }
    return mat;
  }

  /// Gets matrix element at row [r] and column [c].
  double get(int r, int c) => data[r * cols + c];

  /// Sets matrix element at row [r] and column [c].
  void set(int r, int c, double val) => data[r * cols + c] = val;

  /// Matrix multiplication: computes C = this * [other].
  Matrix multiply(Matrix other) {
    if (cols != other.rows) {
      throw ValidationException(
        'Matrix multiplication dimension mismatch: ($rows x $cols) * (${other.rows} x ${other.cols})',
      );
    }
    final result = Matrix(rows, other.cols);
    final a = data;
    final b = other.data;
    final res = result.data;
    final K = cols;
    final N = other.cols;

    // Cache-friendly i-k-j loop structure for cache locality
    for (var i = 0; i < rows; i++) {
      final iOff = i * K;
      final resOff = i * N;
      for (var k = 0; k < K; k++) {
        final aVal = a[iOff + k];
        final bOff = k * N;
        for (var j = 0; j < N; j++) {
          res[resOff + j] += aVal * b[bOff + j];
        }
      }
    }
    return result;
  }

  /// Matrix-Vector multiplication: computes y = A * x.
  Vector multiplyVector(Vector vector) {
    if (cols != vector.length) {
      throw ValidationException(
        'Matrix-Vector multiplication dimension mismatch: ($rows x $cols) * length ${vector.length}',
      );
    }
    final result = Vector(rows);
    final a = data;
    final x = vector.data;
    final y = result.data;
    final C = cols;

    for (var i = 0; i < rows; i++) {
      double sum = 0.0;
      final off = i * C;
      for (var j = 0; j < C; j++) {
        sum += a[off + j] * x[j];
      }
      y[i] = sum;
    }
    return result;
  }

  /// Returns the transposed [Matrix] (cols x rows).
  Matrix transpose() {
    final result = Matrix(cols, rows);
    final src = data;
    final dst = result.data;
    final R = rows;
    final C = cols;

    for (var i = 0; i < R; i++) {
      final srcOff = i * C;
      for (var j = 0; j < C; j++) {
        dst[j * R + i] = src[srcOff + j];
      }
    }
    return result;
  }

  /// Element-wise addition: C = this + [other].
  Matrix add(Matrix other) {
    if (rows != other.rows || cols != other.cols) {
      throw const ValidationException('Matrix dimension mismatch for addition');
    }
    final result = Matrix(rows, cols);
    final total = rows * cols;
    final a = data;
    final b = other.data;
    final res = result.data;
    for (var i = 0; i < total; i++) {
      res[i] = a[i] + b[i];
    }
    return result;
  }

  /// Element-wise subtraction: C = this - [other].
  Matrix subtract(Matrix other) {
    if (rows != other.rows || cols != other.cols) {
      throw const ValidationException('Matrix dimension mismatch for subtraction');
    }
    final result = Matrix(rows, cols);
    final total = rows * cols;
    final a = data;
    final b = other.data;
    final res = result.data;
    for (var i = 0; i < total; i++) {
      res[i] = a[i] - b[i];
    }
    return result;
  }

  /// Extracts row [r] as a [Vector].
  Vector getRow(int r) {
    if (r < 0 || r >= rows) {
      throw ValidationException('Row index $r out of bounds (0..${rows - 1})');
    }
    final rowVec = Vector(cols);
    final srcOff = r * cols;
    rowVec.data.setRange(0, cols, data, srcOff);
    return rowVec;
  }

  /// Extracts column [c] as a [Vector].
  Vector getCol(int c) {
    if (c < 0 || c >= cols) {
      throw ValidationException('Column index $c out of bounds (0..${cols - 1})');
    }
    final colVec = Vector(rows);
    for (var i = 0; i < rows; i++) {
      colVec.data[i] = data[i * cols + c];
    }
    return colVec;
  }

  /// Creates a deep copy of this matrix.
  Matrix clone() {
    final copyBuf = Float32List.fromList(data);
    return Matrix.fromFloat32List(rows, cols, copyBuf);
  }

  @override
  String toString() => 'Matrix($rows x $cols)';
}
