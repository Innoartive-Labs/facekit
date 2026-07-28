import '../matcher/person_record.dart';
import 'face_database_adapter.dart';

/// In-memory RAM database adapter for high-speed local testing and volatile storage.
class MemoryDatabase implements FaceDatabaseAdapter {
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
}
