import '../core/facekit_config.dart';
import '../core/facekit_exception.dart';
import '../embedding/face_embedding.dart';
import 'match_result.dart';
import 'person_record.dart';

/// Pure Dart nearest-neighbor face embedding matcher.
class FaceMatcher {
  /// Active configuration.
  final FaceKitConfig config;

  final Map<String, PersonRecord> _registry = {};

  /// Creates a [FaceMatcher].
  FaceMatcher({FaceKitConfig? config}) : config = config ?? FaceKitConfig.defaultConfig;

  /// Returns total number of registered person records.
  int get registeredCount => _registry.length;

  /// All registered person records.
  List<PersonRecord> get allRecords => _registry.values.toList();

  /// Adds a new [PersonRecord] to active index.
  void addRecord(PersonRecord record, {bool allowUpdate = false}) {
    if (record.personId.trim().isEmpty || record.name.trim().isEmpty) {
      throw const ValidationException('PersonId and Name cannot be empty');
    }
    if (_registry.containsKey(record.personId) && !allowUpdate) {
      throw DatabaseException('PersonId ${record.personId} is already registered');
    }
    _registry[record.personId] = record;
  }

  /// Removes a person record by [personId].
  bool removeRecord(String personId) {
    return _registry.remove(personId) != null;
  }

  /// Gets a registered person record by [personId].
  PersonRecord? getRecord(String personId) => _registry[personId];

  /// Finds nearest neighbor match for a query [FaceEmbedding].
  MatchResult findBestMatch(FaceEmbedding queryEmbedding, {double? threshold}) {
    if (_registry.isEmpty) {
      return MatchResult.unknown();
    }

    final matchThreshold = threshold ?? config.matchingThreshold;
    final metric = config.distanceMetric;

    PersonRecord? bestRecord;
    double bestScore = metric == FaceDistanceMetric.cosine ? -1.0 : double.infinity;

    for (final record in _registry.values) {
      if (metric == FaceDistanceMetric.cosine) {
        final score = queryEmbedding.cosineSimilarity(record.embedding);
        if (score > bestScore) {
          bestScore = score;
          bestRecord = record;
        }
      } else {
        final dist = queryEmbedding.euclideanDistance(record.embedding);
        if (dist < bestScore) {
          bestScore = dist;
          bestRecord = record;
        }
      }
    }

    if (bestRecord == null) {
      return MatchResult.unknown();
    }

    final isMatch = metric == FaceDistanceMetric.cosine
        ? bestScore >= matchThreshold
        : bestScore <= matchThreshold;

    if (isMatch) {
      final conf = metric == FaceDistanceMetric.cosine ? bestScore : (1.0 / (1.0 + bestScore));
      return MatchResult(
        matched: true,
        personId: bestRecord.personId,
        name: bestRecord.name,
        confidence: conf,
        distance: bestScore,
        metadata: bestRecord.metadata,
      );
    }

    return MatchResult.unknown(
      metric == FaceDistanceMetric.cosine ? bestScore : (1.0 / (1.0 + bestScore)),
    );
  }

  /// Clears all registered records from memory.
  void clear() => _registry.clear();
}
