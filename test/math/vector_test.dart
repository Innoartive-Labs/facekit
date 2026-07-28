import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('Vector Tests', () {
    test('creates vector from list and verifies dot product', () {
      final v1 = Vector.fromList([1.0, 2.0, 3.0, 4.0]);
      final v2 = Vector.fromList([2.0, 0.0, -1.0, 5.0]);

      // Dot product: 1*2 + 2*0 + 3*(-1) + 4*5 = 2 + 0 - 3 + 20 = 19
      expect(v1.dot(v2), equals(19.0));
    });

    test('computes norm and normalize', () {
      final v = Vector.fromList([3.0, 4.0]);
      expect(v.norm(), equals(5.0));

      final unit = v.normalize();
      expect(unit[0], closeTo(0.6, 1e-5));
      expect(unit[1], closeTo(0.8, 1e-5));
      expect(unit.norm(), closeTo(1.0, 1e-5));
    });

    test('computes cosine similarity and euclidean distance', () {
      final v1 = Vector.fromList([1.0, 0.0, 0.0]);
      final v2 = Vector.fromList([0.0, 1.0, 0.0]);
      final v3 = Vector.fromList([1.0, 0.0, 0.0]);

      expect(v1.cosineSimilarity(v2), equals(0.0));
      expect(v1.cosineSimilarity(v3), equals(1.0));

      // Euclidean distance between (1,0,0) and (0,1,0) = sqrt(1 + 1) = sqrt(2) ~ 1.414213
      expect(v1.euclideanDistance(v2), closeTo(1.414213, 1e-4));
    });

    test('throws ValidationException on dimension mismatch', () {
      final v1 = Vector(3);
      final v2 = Vector(4);

      expect(() => v1.dot(v2), throwsA(isA<ValidationException>()));
      expect(() => v1.add(v2), throwsA(isA<ValidationException>()));
    });
  });
}
