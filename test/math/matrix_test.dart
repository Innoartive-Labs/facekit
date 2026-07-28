import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('Matrix Tests', () {
    test('creates 2D matrix from rows and accesses elements', () {
      final mat = Matrix.fromRows([
        [1.0, 2.0],
        [3.0, 4.0],
      ]);

      expect(mat.rows, equals(2));
      expect(mat.cols, equals(2));
      expect(mat.get(0, 0), equals(1.0));
      expect(mat.get(0, 1), equals(2.0));
      expect(mat.get(1, 0), equals(3.0));
      expect(mat.get(1, 1), equals(4.0));
    });

    test('matrix multiplication', () {
      final a = Matrix.fromRows([
        [1.0, 2.0],
        [3.0, 4.0],
      ]);
      final b = Matrix.fromRows([
        [2.0, 0.0],
        [1.0, 3.0],
      ]);

      // [1*2+2*1, 1*0+2*3] = [4, 6]
      // [3*2+4*1, 3*0+4*3] = [10, 12]
      final c = a.multiply(b);
      expect(c.get(0, 0), equals(4.0));
      expect(c.get(0, 1), equals(6.0));
      expect(c.get(1, 0), equals(10.0));
      expect(c.get(1, 1), equals(12.0));
    });

    test('matrix transpose', () {
      final a = Matrix.fromRows([
        [1.0, 2.0, 3.0],
        [4.0, 5.0, 6.0],
      ]);
      final t = a.transpose();

      expect(t.rows, equals(3));
      expect(t.cols, equals(2));
      expect(t.get(0, 0), equals(1.0));
      expect(t.get(0, 1), equals(4.0));
      expect(t.get(2, 0), equals(3.0));
      expect(t.get(2, 1), equals(6.0));
    });

    test('matrix vector multiplication', () {
      final m = Matrix.fromRows([
        [1.0, 2.0],
        [3.0, 4.0],
      ]);
      final v = Vector.fromList([5.0, 6.0]);
      // [1*5 + 2*6, 3*5 + 4*6] = [17, 39]
      final y = m.multiplyVector(v);
      expect(y[0], equals(17.0));
      expect(y[1], equals(39.0));
    });
  });
}
