import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('Tensor Tests', () {
    test('creates 3D tensor and verifies access', () {
      final t = Tensor([2, 3, 4]); // 2 channels, 3 rows, 4 cols
      expect(t.size, equals(24));

      t.set3D(1, 2, 3, 42.0);
      expect(t.get3D(1, 2, 3), equals(42.0));
      expect(t.get([1, 2, 3]), equals(42.0));
    });

    test('reshapes tensor correctly', () {
      final t = Tensor([2, 6]);
      t.set([0, 5], 10.0);

      final r = t.reshape([3, 4]);
      expect(r.shape, equals([3, 4]));
      expect(r.data[5], equals(10.0));
    });

    test('throws ValidationException on invalid shape or index', () {
      expect(() => Tensor([-1, 4]), throwsA(isA<ValidationException>()));
      final t = Tensor([2, 2]);
      expect(() => t.get([2, 0]), throwsA(isA<ValidationException>()));
    });
  });
}
