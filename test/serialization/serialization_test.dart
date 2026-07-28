import 'dart:typed_data';
import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('FaceSerializer (.face) Binary Format Tests', () {
    test('encodes and decodes PersonRecord with full fidelity', () {
      final embBuf = Float32List(128);
      for (var i = 0; i < 128; i++) {
        embBuf[i] = i * 0.005;
      }
      final record = PersonRecord(
        personId: 'EMP007',
        name: 'James Bond',
        embedding: FaceEmbedding(embBuf),
        metadata: {'clearance': 'Top Secret', 'agent': 7},
      );

      final encodedBytes = FaceSerializer.encode(record);

      expect(encodedBytes, isNotEmpty);
      expect(encodedBytes.length, greaterThan(512));

      final decoded = FaceSerializer.decode(encodedBytes);

      expect(decoded.personId, equals('EMP007'));
      expect(decoded.name, equals('James Bond'));
      expect(decoded.metadata['clearance'], equals('Top Secret'));
      expect(decoded.metadata['agent'], equals(7));
      expect(decoded.embedding, equals(record.embedding));
    });

    test('detects CRC32 checksum tampering', () {
      final record = PersonRecord(
        personId: 'EMP001',
        name: 'John Doe',
        embedding: FaceEmbedding(Float32List(128)),
      );

      final encoded = FaceSerializer.encode(record);

      // Tamper with byte in the middle of payload
      final tampered = Uint8List.fromList(encoded);
      tampered[20] ^= 0xFF;

      expect(
        () => FaceSerializer.decode(tampered),
        throwsA(isA<SerializationException>()),
      );
    });
  });
}
