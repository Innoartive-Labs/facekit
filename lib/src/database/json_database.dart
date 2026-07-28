import 'dart:convert';
import '../embedding/face_embedding.dart';
import '../matcher/person_record.dart';
import 'face_database_adapter.dart';

/// JSON-format database adapter converting records into structured JSON payloads.
class JsonDatabase implements FaceDatabaseAdapter {
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

  /// Exports database contents as a formatted JSON String.
  String exportJson() {
    final list = _store.values.map((r) {
      return {
        'personId': r.personId,
        'name': r.name,
        'embedding': r.embedding.toList(),
        'metadata': r.metadata,
        'registeredAt': r.registeredAt.toIso8601String(),
      };
    }).toList();
    return jsonEncode(list);
  }

  /// Imports database contents from a JSON String payload.
  void importJson(String jsonStr) {
    final decoded = jsonDecode(jsonStr) as List;
    for (final item in decoded) {
      final map = item as Map<String, dynamic>;
      final embeddingList = (map['embedding'] as List)
          .cast<num>()
          .map((e) => e.toDouble())
          .toList();
      final record = PersonRecord(
        personId: map['personId'] as String,
        name: map['name'] as String,
        embedding: FaceEmbedding.fromList(embeddingList),
        metadata: (map['metadata'] as Map).cast<String, dynamic>(),
        registeredAt: DateTime.parse(map['registeredAt'] as String),
      );
      _store[record.personId] = record;
    }
  }
}
