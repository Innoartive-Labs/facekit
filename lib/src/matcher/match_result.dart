/// Output result returned by FaceKit recognition queries.
class MatchResult {
  /// Whether query face matched a registered subject above threshold.
  final bool matched;

  /// Unique person identifier ("UNKNOWN" if not matched).
  final String personId;

  /// Full name of matched person ("Unknown" if not matched).
  final String name;

  /// Match confidence score (0.0 to 1.0).
  final double confidence;

  /// Raw embedding distance (Cosine similarity or Euclidean distance).
  final double distance;

  /// Associated metadata key-value store.
  final Map<String, dynamic>? metadata;

  /// Creates a [MatchResult].
  const MatchResult({
    required this.matched,
    required this.personId,
    required this.name,
    required this.confidence,
    required this.distance,
    this.metadata,
  });

  /// Factory constructor for unknown unmatched query result.
  factory MatchResult.unknown([double score = 0.0]) {
    return MatchResult(
      matched: false,
      personId: 'UNKNOWN',
      name: 'Unknown',
      confidence: score,
      distance: 0.0,
    );
  }

  @override
  String toString() {
    if (matched) {
      return 'MatchResult(Matched: $personId - $name, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
    }
    return 'MatchResult(Unmatched: Unknown)';
  }
}
