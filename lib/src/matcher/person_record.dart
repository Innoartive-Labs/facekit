import '../embedding/face_embedding.dart';

/// Represents a registered person record stored in FaceKit local index or database.
class PersonRecord {
  /// Unique identifier for person (e.g. "EMP001").
  final String personId;

  /// Full display name of registered person.
  final String name;

  /// 128-dimensional face embedding vector.
  final FaceEmbedding embedding;

  /// Optional user metadata key-value store.
  final Map<String, dynamic> metadata;

  /// Registration timestamp.
  final DateTime registeredAt;

  /// Creates a [PersonRecord].
  PersonRecord({
    required this.personId,
    required this.name,
    required this.embedding,
    Map<String, dynamic>? metadata,
    DateTime? registeredAt,
  }) : metadata = metadata ?? {},
       registeredAt = registeredAt ?? DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonRecord &&
          runtimeType == other.runtimeType &&
          personId == other.personId &&
          name == other.name &&
          embedding == other.embedding;

  @override
  int get hashCode => Object.hash(personId, name, embedding);

  @override
  String toString() => 'PersonRecord(id: $personId, name: $name)';
}
