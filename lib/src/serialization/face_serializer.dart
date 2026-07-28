import 'dart:convert';
import 'dart:typed_data';
import '../core/facekit_exception.dart';
import '../embedding/face_embedding.dart';
import '../landmarks/face_landmark.dart';
import '../matcher/person_record.dart';

/// Pure Dart serializer and parser for custom `.face` binary format files.
abstract class FaceSerializer {
  /// Magic header bytes identifying `.face` files ('FACE' -> 0x46414345).
  static const int magicHeader = 0x46414345;

  /// Current binary format version.
  static const int currentVersion = 1;

  /// Encodes a [PersonRecord] and optional [landmarks] into a `.face` binary byte buffer.
  static Uint8List encode(
    PersonRecord record, {
    List<FaceLandmark>? landmarks,
  }) {
    final builder = BytesBuilder();

    // 1. Magic Header (4 bytes: 'FACE')
    final headerData = ByteData(6);
    headerData.setUint32(0, magicHeader);
    headerData.setUint16(4, currentVersion);
    builder.add(headerData.buffer.asUint8List());

    // 2. Person ID (length-prefixed UTF-8 string)
    final idBytes = utf8.encode(record.personId);
    final idLenData = ByteData(2)..setUint16(0, idBytes.length);
    builder.add(idLenData.buffer.asUint8List());
    builder.add(idBytes);

    // 3. Name (length-prefixed UTF-8 string)
    final nameBytes = utf8.encode(record.name);
    final nameLenData = ByteData(2)..setUint16(0, nameBytes.length);
    builder.add(nameLenData.buffer.asUint8List());
    builder.add(nameBytes);

    // 4. Metadata (length-prefixed JSON UTF-8 string)
    final metaJson = jsonEncode(record.metadata);
    final metaBytes = utf8.encode(metaJson);
    final metaLenData = ByteData(4)..setUint32(0, metaBytes.length);
    builder.add(metaLenData.buffer.asUint8List());
    builder.add(metaBytes);

    // 5. Embedding Vector (128 Float32 values = 512 bytes)
    final embBuf = ByteData(record.embedding.dimension * 4);
    for (var i = 0; i < record.embedding.dimension; i++) {
      embBuf.setFloat32(i * 4, record.embedding.values[i]);
    }
    builder.add(embBuf.buffer.asUint8List());

    // 6. Landmarks
    final pts = landmarks ?? [];
    final lmHeader = ByteData(2)..setUint16(0, pts.length);
    builder.add(lmHeader.buffer.asUint8List());

    if (pts.isNotEmpty) {
      final lmBuf = ByteData(pts.length * 8);
      for (var i = 0; i < pts.length; i++) {
        lmBuf.setFloat32(i * 8, pts[i].x);
        lmBuf.setFloat32(i * 8 + 4, pts[i].y);
      }
      builder.add(lmBuf.buffer.asUint8List());
    }

    // 7. Checksum calculation (CRC32 over payload)
    final payloadBytes = builder.toBytes();
    final checksum = _computeCrc32(payloadBytes);
    final checksumData = ByteData(4)..setUint32(0, checksum);

    final finalBuilder = BytesBuilder();
    finalBuilder.add(payloadBytes);
    finalBuilder.add(checksumData.buffer.asUint8List());

    return finalBuilder.toBytes();
  }

  /// Decodes a `.face` binary byte buffer into a [PersonRecord].
  static PersonRecord decode(Uint8List bytes) {
    if (bytes.length < 16) {
      throw const SerializationException(
        'Corrupt .face binary file: byte length too short',
      );
    }

    // Verify Checksum
    final payloadLen = bytes.length - 4;
    final payload = Uint8List.sublistView(bytes, 0, payloadLen);
    final expectedChecksum = ByteData.sublistView(
      bytes,
      payloadLen,
    ).getUint32(0);
    final actualChecksum = _computeCrc32(payload);

    if (actualChecksum != expectedChecksum) {
      throw SerializationException(
        'CRC32 checksum mismatch in .face binary data (expected: $expectedChecksum, actual: $actualChecksum)',
      );
    }

    final data = ByteData.sublistView(payload);
    var offset = 0;

    // 1. Verify Magic Header
    final magic = data.getUint32(offset);
    offset += 4;
    if (magic != magicHeader) {
      throw SerializationException(
        'Invalid .face magic header: 0x${magic.toRadixString(16)}',
      );
    }

    // 2. Format Version
    final version = data.getUint16(offset);
    offset += 2;
    if (version > currentVersion) {
      throw SerializationException('Unsupported .face version: $version');
    }

    // 3. Person ID
    final idLen = data.getUint16(offset);
    offset += 2;
    final personId = utf8.decode(payload.sublist(offset, offset + idLen));
    offset += idLen;

    // 4. Name
    final nameLen = data.getUint16(offset);
    offset += 2;
    final name = utf8.decode(payload.sublist(offset, offset + nameLen));
    offset += nameLen;

    // 5. Metadata
    final metaLen = data.getUint32(offset);
    offset += 4;
    final metaStr = utf8.decode(payload.sublist(offset, offset + metaLen));
    offset += metaLen;
    final metadata = (jsonDecode(metaStr) as Map).cast<String, dynamic>();

    // 6. Embedding Vector (128 Float32 values)
    const dim = 128;
    final floatBuf = Float32List(dim);
    for (var i = 0; i < dim; i++) {
      floatBuf[i] = data.getFloat32(offset);
      offset += 4;
    }

    return PersonRecord(
      personId: personId,
      name: name,
      embedding: FaceEmbedding(floatBuf),
      metadata: metadata,
    );
  }

  /// CRC32 polynomial calculation.
  static int _computeCrc32(Uint8List buffer) {
    var crc = 0xFFFFFFFF;
    for (var i = 0; i < buffer.length; i++) {
      final byte = buffer[i];
      crc ^= byte;
      for (var j = 0; j < 8; j++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc = crc >> 1;
        }
      }
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}
