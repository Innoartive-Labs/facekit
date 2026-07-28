import 'dart:typed_data';
import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('FaceEmbedder Tests', () {
    test('extracts 128D L2-normalized embedding vector from 112x112 image', () {
      final bytes = Uint8List(112 * 112);
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = (i * 13 + 7) % 256;
      }
      final img = FaceImage.fromGrayscale(bytes, 112, 112);
      final embedder = FaceEmbedder();
      final embedding = embedder.extractEmbedding(img);

      expect(embedding.dimension, equals(128));
      expect(embedding.values.length, equals(128));

      // L2 norm of output vector must be 1.0 (unit vector)
      expect(embedding.toVector().norm(), closeTo(1.0, 1e-4));
    });

    test('identical input image yields identical embedding vectors', () {
      final bytes = Uint8List(112 * 112);
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = (i * 17) % 256;
      }
      final img1 = FaceImage.fromGrayscale(bytes, 112, 112);
      final img2 = FaceImage.fromGrayscale(Uint8List.fromList(bytes), 112, 112);

      final embedder = FaceEmbedder();
      final emb1 = embedder.extractEmbedding(img1);
      final emb2 = embedder.extractEmbedding(img2);

      expect(emb1.cosineSimilarity(emb2), closeTo(1.0, 1e-5));
      expect(emb1.euclideanDistance(emb2), closeTo(0.0, 1e-5));
      expect(emb1, equals(emb2));
    });

    test('throws ValidationException when image size is not 112x112', () {
      final invalidImg = FaceImage.fromGrayscale(Uint8List(64 * 64), 64, 64);
      final embedder = FaceEmbedder();

      expect(
        () => embedder.extractEmbedding(invalidImg),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      'maintains high similarity on smudged/low-contrast image of same subject',
      () {
        const size = 112;
        final bytesA1 = Uint8List(size * size);
        // Create synthetic face pattern for Subject A
        for (var y = 0; y < size; y++) {
          for (var x = 0; x < size; x++) {
            final idx = y * size + x;
            bytesA1[idx] = 120;
            if (y >= 20 && y <= 40 && x >= 25 && x <= 87) {
              bytesA1[idx] = 50; // Eyes region
            }
            if (y >= 45 && y <= 70 && x >= 45 && x <= 67) {
              bytesA1[idx] = 200; // Nose region
            }
            if (y >= 75 && y <= 90 && x >= 35 && x <= 77) {
              bytesA1[idx] = 70; // Mouth region
            }
          }
        }
        final imgA1 = FaceImage.fromGrayscale(bytesA1, size, size);

        // Create smudged/darkened version of Subject A
        final bytesA2 = Uint8List(size * size);
        for (var i = 0; i < bytesA2.length; i++) {
          bytesA2[i] = (bytesA1[i] * 0.6 + 10).round().clamp(0, 255);
        }
        final imgA2 = FaceImage.fromGrayscale(bytesA2, size, size);

        final embedder = FaceEmbedder();
        final embA1 = embedder.extractEmbedding(imgA1);
        final embA2 = embedder.extractEmbedding(imgA2);

        final similarity = embA1.cosineSimilarity(embA2);
        expect(similarity, greaterThanOrEqualTo(0.80));
      },
    );

    test(
      'produces low similarity between distinct subjects (Person A vs Person B)',
      () {
        const size = 112;
        final bytesA = Uint8List(size * size);
        for (var y = 0; y < size; y++) {
          for (var x = 0; x < size; x++) {
            final idx = y * size + x;
            bytesA[idx] = 140;
            if (y >= 20 && y <= 40 && x >= 20 && x <= 50) bytesA[idx] = 40;
            if (y >= 45 && y <= 65 && x >= 40 && x <= 60) bytesA[idx] = 220;
          }
        }
        final imgA = FaceImage.fromGrayscale(bytesA, size, size);

        final bytesB = Uint8List(size * size);
        for (var y = 0; y < size; y++) {
          for (var x = 0; x < size; x++) {
            final idx = y * size + x;
            bytesB[idx] = 60;
            if (y >= 50 && y <= 80 && x >= 60 && x <= 95) bytesB[idx] = 230;
            if (y >= 10 && y <= 30 && x >= 10 && x <= 40) bytesB[idx] = 180;
          }
        }
        final imgB = FaceImage.fromGrayscale(bytesB, size, size);

        final embedder = FaceEmbedder();
        final embA = embedder.extractEmbedding(imgA);
        final embB = embedder.extractEmbedding(imgB);

        final similarity = embA.cosineSimilarity(embB);
        expect(similarity, lessThan(0.65));
      },
    );
  });
}
