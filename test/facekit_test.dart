import 'package:facekit/facekit.dart';
import 'package:test/test.dart';

void main() {
  group('FaceKit Main Facade Tests', () {
    test('initializes with default config', () {
      final facekit = FaceKit();
      expect(facekit.config.detectionThreshold, equals(0.5));
      expect(FaceKit.version, equals('1.0.0'));
    });

    test('initializes with custom config and custom log output', () {
      final logs = <String>[];
      const config = FaceKitConfig(
        detectionThreshold: 0.85,
        logLevel: FaceKitLogLevel.debug,
      );
      final facekit = FaceKit(config: config);
      facekit.logger.onLog = (msg) => logs.add(msg);

      facekit.logger.debug('Testing logger output');
      expect(facekit.config.detectionThreshold, equals(0.85));
      expect(logs, contains(predicate<String>((s) => s.contains('Testing logger output'))));
    });
  });
}
