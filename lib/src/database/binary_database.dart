import 'dart:typed_data';
import '../matcher/person_record.dart';
import '../serialization/face_serializer.dart';
import 'face_database_adapter.dart';

/// Binary `.face` database adapter for multi-record binary storage.
class BinaryDatabase implements FaceDatabaseAdapter {
  final Map<String, PersonRecord> _store = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> insert(PersonRecord record) async {
    _store[record.personId] = record;
  }

  @override
  Future<PersonRecord?> get(String personId) async {
    return _store[personId];
  }

  @override
  Future<List<PersonRecord>> getAll() async {
    return _store.values.toList();
  }

  @override
  Future<bool> delete(String personId) async {
    return _store.remove(personId) != null;
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }

  /// Exports a specific subject as a `.face` binary buffer.
  Uint8List exportBinary(String personId) {
    final record = _store[personId];
    if (record == null) {
      throw ArgumentError('PersonId $personId not found in database');
    }
    return FaceSerializer.encode(record);
  }

  /// Imports a subject from a `.face` binary buffer.
  PersonRecord importBinary(Uint8List bytes) {
    final record = FaceSerializer.decode(bytes);
    _store[record.personId] = record;
    return record;
  }
}
