import 'dart:typed_data';
import 'package:facekit/facekit.dart';

void main() async {
  print('=== FaceKit End-to-End Performance Benchmark ===\n');

  final facekit = FaceKit(config: const FaceKitConfig(logLevel: FaceKitLogLevel.none));

  // Build synthetic test face image (48x48)
  const size = 48;
  final bytes = Uint8List(size * size);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final idx = y * size + x;
      bytes[idx] = 120;
      if (y >= 5 && y <= 15 && x >= 10 && x <= 38) bytes[idx] = 220;
      if (y >= 16 && y <= 25 && x >= 8 && x <= 40) bytes[idx] = 30;
      if (y >= 18 && y <= 35 && x >= 20 && x <= 28) bytes[idx] = 200;
    }
  }
  final img = FaceImage.fromGrayscale(bytes, size, size);

  // 1. Registration Latency Benchmark
  final regSw = Stopwatch()..start();
  const regIters = 10;
  for (var i = 0; i < regIters; i++) {
    await facekit.register(
      image: img,
      personId: 'BENCH_$i',
      name: 'Subject $i',
      overwrite: true,
    );
  }
  regSw.stop();
  final regMs = regSw.elapsedMilliseconds / regIters;
  print('Registration Latency (Detect -> Landmark -> Align -> Embed): ${regMs.toStringAsFixed(2)} ms/subject');

  // 2. Recognition Query Latency Benchmark
  final recSw = Stopwatch()..start();
  const recIters = 20;
  for (var i = 0; i < recIters; i++) {
    await facekit.recognize(img);
  }
  recSw.stop();
  final recMs = recSw.elapsedMilliseconds / recIters;
  print('Recognition Latency (Query -> Match 10 Registered): ${recMs.toStringAsFixed(2)} ms/query');

  // 3. Binary Serialization (.face) Throughput Benchmark
  final record = facekit.matcher.getRecord('BENCH_0')!;
  final serSw = Stopwatch()..start();
  const serIters = 1000;
  for (var i = 0; i < serIters; i++) {
    final bin = FaceSerializer.encode(record);
    FaceSerializer.decode(bin);
  }
  serSw.stop();
  final serMs = serSw.elapsedMilliseconds / serIters;
  print('.face Serialization + Deserialization Throughput: ${serMs.toStringAsFixed(3)} ms/op');

  print('\nPerformance benchmarks completed successfully!');
}
