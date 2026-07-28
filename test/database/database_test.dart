import 'dart:typed_data';
import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('Database Adapters and Import/Export Tests', () {
    test('MemoryDatabase CRUD operations', () async {
      final db = MemoryDatabase();
      await db.init();

      final record = PersonRecord(
        personId: 'EMP001',
        name: 'John Doe',
        embedding: FaceEmbedding(Float32List(128)),
      );

      await db.insert(record);
      expect((await db.getAll()).length, equals(1));
      expect(await db.get('EMP001'), equals(record));

      final deleted = await db.delete('EMP001');
      expect(deleted, isTrue);
      expect((await db.getAll()).length, equals(0));
    });

    test('JsonDatabase import and export', () async {
      final db = JsonDatabase();
      final record = PersonRecord(
        personId: 'EMP002',
        name: 'Jane Smith',
        embedding: FaceEmbedding(Float32List(128)),
      );

      await db.insert(record);
      final jsonStr = db.exportJson();

      final db2 = JsonDatabase();
      db2.importJson(jsonStr);

      final imported = await db2.get('EMP002');
      expect(imported, isNotNull);
      expect(imported!.name, equals('Jane Smith'));
    });

    test('FaceKit high-level JSON and Binary database import/export', () async {
      final facekit = FaceKit(config: const FaceKitConfig(logLevel: FaceKitLogLevel.none));
      final record = PersonRecord(
        personId: 'EMP100',
        name: 'Alice Cooper',
        embedding: FaceEmbedding(Float32List(128)),
      );

      facekit.matcher.addRecord(record);

      // JSON Export/Import
      final jsonExport = await facekit.exportDatabaseJson();
      final facekit2 = FaceKit(config: const FaceKitConfig(logLevel: FaceKitLogLevel.none));
      await facekit2.importDatabaseJson(jsonExport);

      expect(facekit2.registeredCount, equals(1));
      expect(facekit2.matcher.getRecord('EMP100')?.name, equals('Alice Cooper'));

      // Binary Export/Import
      final binaryExport = await facekit.exportPersonBinary('EMP100');
      final facekit3 = FaceKit(config: const FaceKitConfig(logLevel: FaceKitLogLevel.none));
      final importedRecord = await facekit3.importPersonBinary(binaryExport);

      expect(importedRecord.personId, equals('EMP100'));
      expect(facekit3.registeredCount, equals(1));
    });
  });
}
