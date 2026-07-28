/// Base exception class for all errors occurring within the FaceKit library.
abstract class FaceKitException implements Exception {
  /// Human-readable message describing the exception.
  final String message;

  /// Optional underlying cause or details.
  final Object? details;

  /// Creates a new [FaceKitException] with the given [message] and optional [details].
  const FaceKitException(this.message, [this.details]);

  @override
  String toString() {
    if (details != null) {
      return '$runtimeType: $message (Details: $details)';
    }
    return '$runtimeType: $message';
  }
}

/// Thrown when an input image is invalid, corrupt, or unsupported.
class InvalidImageException extends FaceKitException {
  /// Creates an [InvalidImageException].
  const InvalidImageException(super.message, [super.details]);
}

/// Thrown when model weights or network initialization fails.
class ModelInitializationException extends FaceKitException {
  /// Creates a [ModelInitializationException].
  const ModelInitializationException(super.message, [super.details]);
}

/// Thrown when face detection or landmark detection operations fail.
class FaceDetectionException extends FaceKitException {
  /// Creates a [FaceDetectionException].
  const FaceDetectionException(super.message, [super.details]);
}

/// Thrown when local database operations (storage, query, deletion) fail.
class DatabaseException extends FaceKitException {
  /// Creates a [DatabaseException].
  const DatabaseException(super.message, [super.details]);
}

/// Thrown when `.face` binary format serialization or deserialization fails.
class SerializationException extends FaceKitException {
  /// Creates a [SerializationException].
  const SerializationException(super.message, [super.details]);
}

/// Thrown when input validation checks fail (e.g. invalid parameters or dimensions).
class ValidationException extends FaceKitException {
  /// Creates a [ValidationException].
  const ValidationException(super.message, [super.details]);
}
