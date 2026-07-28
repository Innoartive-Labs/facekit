import 'dart:typed_data';
import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('FaceMatcher and FaceKit High-Level API Tests', () {
    test('registers subject and recognizes correctly', () async {
      final facekit = FaceKit(config: const FaceKitConfig(logLevel: FaceKitLogLevel.none));

      // Build synthetic face pattern image (48x48)
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

      final record = await facekit.register(
        image: img,
        personId: 'EMP001',
        name: 'John Doe',
        metadata: {'department': 'Engineering'},
      );

      expect(record.personId, equals('EMP001'));
      expect(record.name, equals('John Doe'));
      expect(facekit.registeredCount, equals(1));

      // Query recognition
      final result = await facekit.recognize(img);

      expect(result.matched, isTrue);
      expect(result.personId, equals('EMP001'));
      expect(result.name, equals('John Doe'));
      expect(result.confidence, greaterThanOrEqualTo(0.5));
    });

    test('returns UNKNOWN for unregistered face image when empty', () async {
      final facekit = FaceKit(config: const FaceKitConfig(logLevel: FaceKitLogLevel.none));
      final img = FaceImage.fromGrayscale(Uint8List(48 * 48), 48, 48);

      final result = await facekit.recognize(img);
      expect(result.matched, isFalse);
      expect(result.personId, equals('UNKNOWN'));
    });

    test('deletes registered person', () async {
      final facekit = FaceKit(config: const FaceKitConfig(logLevel: FaceKitLogLevel.none));
      final emb = FaceEmbedding(Float32List(128));
      final record = PersonRecord(personId: 'EMP002', name: 'Jane Doe', embedding: emb);

      facekit.matcher.addRecord(record);
      expect(facekit.registeredCount, equals(1));

      final deleted = await facekit.delete('EMP002');
      expect(deleted, isTrue);
      expect(facekit.registeredCount, equals(0));
    });

    test('recognizes smudged or dark image of Person A correctly', () async {
      final facekit = FaceKit(config: const FaceKitConfig(logLevel: FaceKitLogLevel.none));
      const size = 64;

      final bytesA = Uint8List(size * size);
      for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
          final idx = y * size + x;
          bytesA[idx] = 130;
          if (y >= 10 && y <= 25 && x >= 15 && x <= 45) bytesA[idx] = 40;
          if (y >= 30 && y <= 45 && x >= 25 && x <= 38) bytesA[idx] = 210;
        }
      }
      final imgA = FaceImage.fromGrayscale(bytesA, size, size);

      await facekit.register(
        image: imgA,
        personId: 'EMP_A',
        name: 'Person A',
      );

      // Query with darkened/smudged version of Person A
      final bytesASmudged = Uint8List(size * size);
      for (var i = 0; i < bytesASmudged.length; i++) {
        bytesASmudged[i] = (bytesA[i] * 0.5 + 15).round().clamp(0, 255);
      }
      final imgASmudged = FaceImage.fromGrayscale(bytesASmudged, size, size);

      final result = await facekit.recognize(imgASmudged);

      expect(result.matched, isTrue);
      expect(result.personId, equals('EMP_A'));
      expect(result.name, equals('Person A'));
    });

    test('rejects Person B when Person A is registered (no false match)', () async {
      final facekit = FaceKit(config: const FaceKitConfig(logLevel: FaceKitLogLevel.none));
      const size = 64;

      final bytesA = Uint8List(size * size);
      for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
          final idx = y * size + x;
          bytesA[idx] = 130;
          if (y >= 10 && y <= 25 && x >= 15 && x <= 45) bytesA[idx] = 40;
        }
      }
      final imgA = FaceImage.fromGrayscale(bytesA, size, size);

      await facekit.register(
        image: imgA,
        personId: 'EMP_A',
        name: 'Person A',
      );

      // Person B has completely different feature layout
      final bytesB = Uint8List(size * size);
      for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
          final idx = y * size + x;
          bytesB[idx] = 70;
          if (y >= 35 && y <= 55 && x >= 30 && x <= 60) bytesB[idx] = 220;
        }
      }
      final imgB = FaceImage.fromGrayscale(bytesB, size, size);

      final result = await facekit.recognize(imgB);
      expect(result.matched, isFalse);
      expect(result.personId, equals('UNKNOWN'));
    });
  });
}

