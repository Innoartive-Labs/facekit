import 'package:facekit/facekit.dart';

void main() {
  print('=== FaceKit Phase 2 Pure Dart Math Engine Benchmarks ===\n');

  // 1. Vector Dot Product Benchmark
  const vecSize = 100000;
  final v1 = Vector(vecSize);
  final v2 = Vector(vecSize);
  for (var i = 0; i < vecSize; i++) {
    v1[i] = i * 0.001;
    v2[i] = (vecSize - i) * 0.001;
  }

  final vSw = Stopwatch()..start();
  double dotSum = 0.0;
  const vIters = 500;
  for (var k = 0; k < vIters; k++) {
    dotSum += v1.dot(v2);
  }
  vSw.stop();
  final vMs = vSw.elapsedMilliseconds / vIters;
  print('Vector Dot Product (dim: $vecSize): ${vMs.toStringAsFixed(3)} ms/iter (Result: $dotSum)');

  // 2. Matrix Multiplication Benchmark (64x64)
  final m1 = Matrix(64, 64);
  final m2 = Matrix(64, 64);
  for (var i = 0; i < 64; i++) {
    for (var j = 0; j < 64; j++) {
      m1.set(i, j, (i + j) * 0.01);
      m2.set(i, j, (i - j) * 0.01);
    }
  }

  final mSw = Stopwatch()..start();
  const mIters = 100;
  for (var k = 0; k < mIters; k++) {
    m1.multiply(m2);
  }
  mSw.stop();
  final mMs = mSw.elapsedMilliseconds / mIters;
  print('Matrix Multiply (64x64): ${mMs.toStringAsFixed(3)} ms/iter');

  // 3. Conv2D Benchmark (32 channels, 28x28 input with 32x32x3x3 kernel)
  final inputTensor = Tensor([32, 28, 28]);
  final kernelTensor = Tensor([32, 32, 3, 3]);

  final cSw = Stopwatch()..start();
  MathOperations.conv2d(inputTensor, kernelTensor, padding: 1);
  cSw.stop();
  print('Conv2D (In:[32, 28, 28], Kernel:[32, 32, 3, 3]): ${cSw.elapsedMilliseconds} ms');

  print('\nMath Engine benchmarks complete successfully!');
}
