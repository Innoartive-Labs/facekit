import 'dart:typed_data';
import 'alignment/face_aligner.dart';
import 'core/facekit_config.dart';
import 'core/facekit_exception.dart';
import 'core/logger.dart';
import 'database/binary_database.dart';
import 'database/json_database.dart';
import 'detector/face_detector.dart';
import 'embedding/face_embedder.dart';
import 'image/face_image.dart';
import 'landmarks/landmark_detector.dart';
import 'matcher/face_matcher.dart';
import 'matcher/match_result.dart';
import 'matcher/person_record.dart';

/// Main entry point for the FaceKit pure Dart offline facial recognition engine.
class FaceKit {
  /// Active configuration for this FaceKit instance.
  final FaceKitConfig config;

  /// Internal logger instance.
  final FaceKitLogger logger;

  late final FaceDetector _detector;
  late final LandmarkDetector _landmarkDetector;
  late final FaceAligner _aligner;
  late final FaceEmbedder _embedder;
  late final FaceMatcher _matcher;

  /// Creates a new [FaceKit] engine instance with optional [config].
  FaceKit({FaceKitConfig? config})
    : config = config ?? FaceKitConfig.defaultConfig,
      logger = FaceKitLogger(
        level: (config ?? FaceKitConfig.defaultConfig).logLevel,
      ) {
    _detector = FaceDetector(config: this.config);
    _landmarkDetector = LandmarkDetector(config: this.config);
    _aligner = FaceAligner(config: this.config);
    _embedder = FaceEmbedder(config: this.config);
    _matcher = FaceMatcher(config: this.config);

    logger.info('FaceKit engine initialized successfully (v1.0.0)');
  }

  /// Package version identifier.
  static const String version = '1.0.0';

  /// Number of registered subjects in local memory index.
  int get registeredCount => _matcher.registeredCount;

  /// Registers a person in local index from a facial image.
  Future<PersonRecord> register({
    required FaceImage image,
    required String personId,
    required String name,
    Map<String, dynamic>? metadata,
    bool overwrite = false,
  }) async {
    logger.info('Registering person: $personId ($name)');

    final faces = _detector.detectFaces(image, maxFaces: 1);
    if (faces.isEmpty) {
      throw const FaceDetectionException(
        'No face detected in provided registration image',
      );
    }
    final face = faces.first;

    final landmarks = _landmarkDetector.detectLandmarks(image, face);
    final alignedFace = _aligner.alignFace(image, face, landmarks);
    final embedding = _embedder.extractEmbedding(alignedFace);

    final record = PersonRecord(
      personId: personId,
      name: name,
      embedding: embedding,
      metadata: metadata,
    );

    _matcher.addRecord(record, allowUpdate: overwrite);
    logger.info('Person $personId registered successfully');
    return record;
  }

  /// Recognizes the primary face present in the query [image].
  Future<MatchResult> recognize(FaceImage image, {double? threshold}) async {
    logger.debug('Executing face recognition query...');

    final faces = _detector.detectFaces(image, maxFaces: 1);
    if (faces.isEmpty) {
      logger.warning('No face detected in query image');
      return MatchResult.unknown();
    }
    final face = faces.first;

    final landmarks = _landmarkDetector.detectLandmarks(image, face);
    final alignedFace = _aligner.alignFace(image, face, landmarks);
    final embedding = _embedder.extractEmbedding(alignedFace);

    final result = _matcher.findBestMatch(embedding, threshold: threshold);
    logger.info('Recognition query complete: $result');
    return result;
  }

  /// Recognizes all faces present in a multi-face [image].
  Future<List<MatchResult>> recognizeMultiple(
    FaceImage image, {
    double? threshold,
  }) async {
    final faces = _detector.detectFaces(image);
    final results = <MatchResult>[];

    for (final face in faces) {
      final landmarks = _landmarkDetector.detectLandmarks(image, face);
      final alignedFace = _aligner.alignFace(image, face, landmarks);
      final embedding = _embedder.extractEmbedding(alignedFace);

      results.add(_matcher.findBestMatch(embedding, threshold: threshold));
    }

    return results;
  }

  /// Deletes a registered person record by [personId].
  Future<bool> delete(String personId) async {
    logger.info('Deleting person record: $personId');
    return _matcher.removeRecord(personId);
  }

  /// Updates an existing registered person's details or metadata.
  Future<PersonRecord> update({
    required String personId,
    required String name,
    FaceImage? newImage,
    Map<String, dynamic>? metadata,
  }) async {
    final existing = _matcher.getRecord(personId);
    if (existing == null) {
      throw DatabaseException('PersonId $personId not found in registry');
    }

    var embedding = existing.embedding;
    if (newImage != null) {
      final faces = _detector.detectFaces(newImage, maxFaces: 1);
      if (faces.isNotEmpty) {
        final landmarks = _landmarkDetector.detectLandmarks(
          newImage,
          faces.first,
        );
        final aligned = _aligner.alignFace(newImage, faces.first, landmarks);
        embedding = _embedder.extractEmbedding(aligned);
      }
    }

    final updated = PersonRecord(
      personId: personId,
      name: name,
      embedding: embedding,
      metadata: metadata ?? existing.metadata,
    );

    _matcher.addRecord(updated, allowUpdate: true);
    return updated;
  }

  /// Exports full database as a JSON string payload.
  Future<String> exportDatabaseJson() async {
    final db = JsonDatabase();
    for (final record in _matcher.allRecords) {
      await db.insert(record);
    }
    return db.exportJson();
  }

  /// Imports database records from a JSON string payload.
  Future<void> importDatabaseJson(String jsonStr) async {
    final db = JsonDatabase()..importJson(jsonStr);
    for (final record in await db.getAll()) {
      _matcher.addRecord(record, allowUpdate: true);
    }
  }

  /// Exports a single registered person as a `.face` binary buffer.
  Future<Uint8List> exportPersonBinary(String personId) async {
    final record = _matcher.getRecord(personId);
    if (record == null) {
      throw DatabaseException('PersonId $personId not found in database');
    }
    final db = BinaryDatabase();
    await db.insert(record);
    return db.exportBinary(personId);
  }

  /// Imports a person from a `.face` binary buffer.
  Future<PersonRecord> importPersonBinary(Uint8List bytes) async {
    final db = BinaryDatabase();
    final record = db.importBinary(bytes);
    _matcher.addRecord(record, allowUpdate: true);
    return record;
  }

  /// Access internal matcher instance.
  FaceMatcher get matcher => _matcher;
}
