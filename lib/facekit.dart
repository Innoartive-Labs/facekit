/// Pure Dart offline facial recognition engine.
///
/// Features:
/// - Zero external native C/C++ dependencies or bindings.
/// - Zero TensorFlow / TFLite / ONNX runtime dependencies.
/// - 100% offline, privacy-preserving, cross-platform Dart execution.
library;

export 'src/alignment/face_aligner.dart';
export 'src/core/facekit_config.dart';
export 'src/core/facekit_exception.dart';
export 'src/core/geometry.dart';
export 'src/core/logger.dart';
export 'src/database/binary_database.dart';
export 'src/database/face_database_adapter.dart';
export 'src/database/json_database.dart';
export 'src/database/memory_database.dart';
export 'src/detector/face.dart';
export 'src/detector/face_detector.dart';
export 'src/embedding/face_embedder.dart';
export 'src/embedding/face_embedding.dart';
export 'src/facekit_base.dart';
export 'src/image/face_image.dart';
export 'src/image/image_processor.dart';
export 'src/image/integral_image.dart';
export 'src/landmarks/face_landmark.dart';
export 'src/landmarks/landmark_detector.dart';
export 'src/matcher/face_matcher.dart';
export 'src/matcher/match_result.dart';
export 'src/matcher/person_record.dart';
export 'src/math/matrix.dart';
export 'src/math/operations.dart';
export 'src/math/tensor.dart';
export 'src/math/vector.dart';
export 'src/serialization/face_serializer.dart';
export 'src/utils/typed_buffer_utils.dart';
