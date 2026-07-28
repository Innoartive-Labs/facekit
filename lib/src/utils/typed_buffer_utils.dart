import 'dart:typed_data';
import '../core/facekit_exception.dart';

/// Performance and safety utilities for working with [TypedData] buffers.
abstract class TypedBufferUtils {
  /// Allocates a contiguous [Uint8List] of specified [bytes].
  static Uint8List allocateUint8(int bytes) {
    if (bytes <= 0) {
      throw ValidationException('Buffer byte allocation size must be positive: $bytes');
    }
    return Uint8List(bytes);
  }

  /// Allocates a contiguous [Float32List] of specified [elements].
  static Float32List allocateFloat32(int elements) {
    if (elements <= 0) {
      throw ValidationException('Float array length must be positive: $elements');
    }
    return Float32List(elements);
  }

  /// Fast memory copy from source [Uint8List] to target [Uint8List].
  static void copyUint8(
    Uint8List source,
    Uint8List destination, {
    int sourceOffset = 0,
    int destinationOffset = 0,
    int? length,
  }) {
    final len = length ?? (source.length - sourceOffset);
    if (sourceOffset + len > source.length || destinationOffset + len > destination.length) {
      throw const ValidationException('Buffer copy offset out of bounds');
    }
    destination.setRange(destinationOffset, destinationOffset + len, source, sourceOffset);
  }

  /// Converts an RGBA byte buffer to a 3-channel RGB buffer.
  static Uint8List rgbaToRgb(Uint8List rgbaBuffer, int width, int height) {
    final pixelCount = width * height;
    if (rgbaBuffer.length < pixelCount * 4) {
      throw InvalidImageException(
        'RGBA buffer size ${rgbaBuffer.length} is less than required ${pixelCount * 4}',
      );
    }
    final rgb = Uint8List(pixelCount * 3);
    var srcIdx = 0;
    var dstIdx = 0;
    for (var i = 0; i < pixelCount; i++) {
      rgb[dstIdx] = rgbaBuffer[srcIdx];
      rgb[dstIdx + 1] = rgbaBuffer[srcIdx + 1];
      rgb[dstIdx + 2] = rgbaBuffer[srcIdx + 2];
      srcIdx += 4;
      dstIdx += 3;
    }
    return rgb;
  }

  /// Converts an RGB byte buffer to a 1-channel Grayscale buffer using standard luminance.
  /// (Luminance = 0.299 * R + 0.587 * G + 0.114 * B)
  static Uint8List rgbToGrayscale(Uint8List rgbBuffer, int width, int height) {
    final pixelCount = width * height;
    if (rgbBuffer.length < pixelCount * 3) {
      throw InvalidImageException(
        'RGB buffer size ${rgbBuffer.length} is less than required ${pixelCount * 3}',
      );
    }
    final gray = Uint8List(pixelCount);
    var srcIdx = 0;
    for (var i = 0; i < pixelCount; i++) {
      final r = rgbBuffer[srcIdx];
      final g = rgbBuffer[srcIdx + 1];
      final b = rgbBuffer[srcIdx + 2];
      // Fixed point integer scaling for high efficiency: (299*R + 587*G + 114*B) >> 10
      gray[i] = ((299 * r + 587 * g + 114 * b) >> 10).clamp(0, 255);
      srcIdx += 3;
    }
    return gray;
  }
}
