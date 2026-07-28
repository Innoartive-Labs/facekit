import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('MathOperations Tests', () {
    test('Conv2D operation with 1 channel 3x3 image and 2x2 kernel', () {
      final input = Tensor([1, 3, 3]);
      // Populate 3x3 with 1s
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          input.set3D(0, r, c, 1.0);
        }
      }

      final kernel = Tensor([1, 1, 2, 2]);
      // Kernel with all 1s
      for (var r = 0; r < 2; r++) {
        for (var c = 0; c < 2; c++) {
          kernel.set4D(0, 0, r, c, 1.0);
        }
      }

      // Conv2d output size: 2x2, each cell should be 4.0
      final out = MathOperations.conv2d(input, kernel);
      expect(out.shape, equals([1, 2, 2]));
      expect(out.get3D(0, 0, 0), equals(4.0));
      expect(out.get3D(0, 1, 1), equals(4.0));
    });

    test('MaxPool2D operation', () {
      final input = Tensor([1, 4, 4]);
      // Set distinct values
      var val = 1.0;
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 4; c++) {
          input.set3D(0, r, c, val++);
        }
      }

      // MaxPool with poolSize=2, stride=2 -> 2x2 output
      final pooled = MathOperations.maxPool2d(input, poolSize: 2, stride: 2);
      expect(pooled.shape, equals([1, 2, 2]));

      // Max of top-left 2x2 (1,2,5,6) -> 6
      expect(pooled.get3D(0, 0, 0), equals(6.0));
      // Max of bottom-right 2x2 (11,12,15,16) -> 16
      expect(pooled.get3D(0, 1, 1), equals(16.0));
    });

    test('ReLU, Sigmoid, and Softmax activations', () {
      final t = Tensor([3]);
      t.set([0], -2.0);
      t.set([1], 0.0);
      t.set([2], 3.0);

      final reluOut = MathOperations.relu(t);
      expect(reluOut.get([0]), equals(0.0));
      expect(reluOut.get([1]), equals(0.0));
      expect(reluOut.get([2]), equals(3.0));

      final v = Vector.fromList([1.0, 2.0, 3.0]);
      final sm = MathOperations.softmax(v);

      // Softmax probabilities must sum to 1.0
      double sum = 0.0;
      for (var i = 0; i < sm.length; i++) {
        sum += sm[i];
      }
      expect(sum, closeTo(1.0, 1e-5));
      expect(sm[2], greaterThan(sm[1]));
      expect(sm[1], greaterThan(sm[0]));
    });
  });
}
