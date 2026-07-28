import 'dart:typed_data';
import 'package:facekit/facekit.dart';

void main() {
  print('=== FaceKit Accuracy Benchmark ===\n');

  final embedder = FaceEmbedder();

  const size = 112;

  // Create Subject A image 1 (Face structure A: eyes at top-middle, nose at center)
  final bytesA1 = Uint8List(size * size);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final idx = y * size + x;
      bytesA1[idx] = 130;
      if (y >= 25 && y <= 40 && x >= 25 && x <= 87) {
        bytesA1[idx] = 45; // Eyes region
      }
      if (y >= 45 && y <= 70 && x >= 45 && x <= 67) {
        bytesA1[idx] = 210; // Nose region
      }
      if (y >= 78 && y <= 92 && x >= 35 && x <= 77) {
        bytesA1[idx] = 65; // Mouth region
      }
    }
  }
  final imgA1 = FaceImage.fromGrayscale(bytesA1, size, size);

  // Create Subject A image 2 (Smudged / low-contrast / dimmed variation of Subject A)
  final bytesA2 = Uint8List(size * size);
  for (var i = 0; i < bytesA2.length; i++) {
    bytesA2[i] = (bytesA1[i] * 0.7 + 25).round().clamp(0, 255);
  }

  final imgA2 = FaceImage.fromGrayscale(bytesA2, size, size);

  // Create Subject B image (Distinct face structure B: wider eyes, lower nose, high mouth)
  final bytesB = Uint8List(size * size);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final idx = y * size + x;
      bytesB[idx] = 75;
      if (y >= 15 && y <= 30 && x >= 15 && x <= 45) {
        bytesB[idx] = 220; // Left feature
      }
      if (y >= 55 && y <= 85 && x >= 55 && x <= 95) {
        bytesB[idx] = 35; // Right feature
      }
    }
  }

  final imgB = FaceImage.fromGrayscale(bytesB, size, size);

  final embA1 = embedder.extractEmbedding(imgA1);
  final embA2 = embedder.extractEmbedding(imgA2);
  final embB = embedder.extractEmbedding(imgB);

  final intraSim = embA1.cosineSimilarity(embA2);
  final interSim = embA1.cosineSimilarity(embB);

  print(
    'Intra-class similarity (Same Subject A clear vs smudged): ${(intraSim * 100).toStringAsFixed(2)}%',
  );
  print(
    'Inter-class similarity (Subject A vs Subject B): ${(interSim * 100).toStringAsFixed(2)}%',
  );
  print(
    'Discriminative Margin: ${((intraSim - interSim) * 100).toStringAsFixed(2)}%',
  );

  if (intraSim > interSim + 0.20) {
    print(
      '\n[SUCCESS] Accuracy Benchmark Passed: High intra-class similarity, low inter-class similarity!',
    );
  }
}
