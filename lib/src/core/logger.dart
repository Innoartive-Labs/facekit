/// Log levels supported by FaceKit logger.
enum FaceKitLogLevel {
  /// No output.
  none,

  /// Critical errors only.
  error,

  /// Warnings and errors.
  warning,

  /// General informative messages, warnings, and errors.
  info,

  /// Verbose debugging output.
  debug,
}

/// Lightweight zero-dependency logger for FaceKit diagnostics.
class FaceKitLogger {
  /// Active logging level.
  FaceKitLogLevel level;

  /// Custom log output handler (defaults to print).
  void Function(String message)? onLog;

  /// Creates a [FaceKitLogger] with specified [level] and optional [onLog] callback.
  FaceKitLogger({this.level = FaceKitLogLevel.info, this.onLog});

  /// Logs a debug message.
  void debug(String message) {
    _log(FaceKitLogLevel.debug, 'DEBUG', message);
  }

  /// Logs an informational message.
  void info(String message) {
    _log(FaceKitLogLevel.info, 'INFO', message);
  }

  /// Logs a warning message.
  void warning(String message) {
    _log(FaceKitLogLevel.warning, 'WARN', message);
  }

  /// Logs an error message.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    final fullMsg = error != null ? '$message | Details: $error' : message;
    _log(FaceKitLogLevel.error, 'ERROR', fullMsg);
    if (stackTrace != null && level.index >= FaceKitLogLevel.error.index) {
      _emit('[FaceKit:ERROR] StackTrace:\n$stackTrace');
    }
  }

  void _log(FaceKitLogLevel msgLevel, String prefix, String message) {
    if (level.index >= msgLevel.index && level != FaceKitLogLevel.none) {
      _emit('[FaceKit:$prefix] $message');
    }
  }

  void _emit(String text) {
    if (onLog != null) {
      onLog!(text);
    } else {
      // Ignore: avoid_print
      print(text);
    }
  }
}
