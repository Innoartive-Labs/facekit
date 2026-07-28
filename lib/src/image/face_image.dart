import 'dart:typed_data';
import '../core/facekit_exception.dart';
import '../utils/typed_buffer_utils.dart';

/// Pixel color format supported by [FaceImage].
enum ImageFormat {
  /// 3-channel Red, Green, Blue.
  rgb,

  /// 4-channel Red, Green, Blue, Alpha.
  rgba,

  /// 1-channel Grayscale.
  grayscale,
}

/// Representation of a single pixel color value.
class Pixel {
  /// Red channel value (0 to 255).
  final int r;

  /// Green channel value (0 to 255).
  final int g;

  /// Blue channel value (0 to 255).
  final int b;

  /// Alpha channel value (0 to 255).
  final int a;

  /// Creates a [Pixel] with RGBA values.
  const Pixel(this.r, this.g, this.b, [this.a = 255]);

  /// Creates a grayscale [Pixel].
  const Pixel.gray(int luminance)
      : r = luminance,
        g = luminance,
        b = luminance,
        a = 255;

  @override
  String toString() => 'Pixel(R:$r, G:$g, B:$b, A:$a)';
}

/// Pure Dart image representation backed by contiguous [Uint8List] typed buffers.
class FaceImage {
  /// Image width in pixels.
  final int width;

  /// Image height in pixels.
  final int height;

  /// Pixel color encoding format.
  final ImageFormat format;

  /// Raw byte buffer holding pixel data.
  final Uint8List buffer;

  /// Number of byte channels per pixel (3 for RGB, 4 for RGBA, 1 for Grayscale).
  final int channels;

  /// Number of bytes per row of pixels.
  final int rowStride;

  /// Creates a [FaceImage] with direct buffer binding and validation.
  FaceImage._({
    required this.width,
    required this.height,
    required this.format,
    required this.buffer,
    required this.channels,
  }) : rowStride = width * channels {
    if (width <= 0 || height <= 0) {
      throw InvalidImageException('Image dimensions must be positive ($width x $height)');
    }
    final expectedBytes = width * height * channels;
    if (buffer.length < expectedBytes) {
      throw InvalidImageException(
        'Image buffer size (${buffer.length}) is smaller than required ($expectedBytes) for format $format',
      );
    }
  }

  /// Creates an RGB [FaceImage].
  factory FaceImage.fromRgb(Uint8List bytes, int width, int height) {
    return FaceImage._(
      width: width,
      height: height,
      format: ImageFormat.rgb,
      buffer: bytes,
      channels: 3,
    );
  }

  /// Creates an RGBA [FaceImage].
  factory FaceImage.fromRgba(Uint8List bytes, int width, int height) {
    return FaceImage._(
      width: width,
      height: height,
      format: ImageFormat.rgba,
      buffer: bytes,
      channels: 4,
    );
  }

  /// Creates a Grayscale [FaceImage].
  factory FaceImage.fromGrayscale(Uint8List bytes, int width, int height) {
    return FaceImage._(
      width: width,
      height: height,
      format: ImageFormat.grayscale,
      buffer: bytes,
      channels: 1,
    );
  }

  /// Converts this image into a 1-channel Grayscale [FaceImage].
  FaceImage toGrayscale() {
    if (format == ImageFormat.grayscale) {
      return clone();
    }
    final rgbBuf = format == ImageFormat.rgb
        ? buffer
        : TypedBufferUtils.rgbaToRgb(buffer, width, height);
    final grayBuf = TypedBufferUtils.rgbToGrayscale(rgbBuf, width, height);
    return FaceImage.fromGrayscale(grayBuf, width, height);
  }

  /// Converts this image into a 3-channel RGB [FaceImage].
  FaceImage toRgb() {
    if (format == ImageFormat.rgb) {
      return clone();
    }
    if (format == ImageFormat.rgba) {
      final rgbBuf = TypedBufferUtils.rgbaToRgb(buffer, width, height);
      return FaceImage.fromRgb(rgbBuf, width, height);
    }
    // Grayscale to RGB conversion
    final rgbBuf = Uint8List(width * height * 3);
    var srcIdx = 0;
    var dstIdx = 0;
    final totalPixels = width * height;
    for (var i = 0; i < totalPixels; i++) {
      final val = buffer[srcIdx++];
      rgbBuf[dstIdx] = val;
      rgbBuf[dstIdx + 1] = val;
      rgbBuf[dstIdx + 2] = val;
      dstIdx += 3;
    }
    return FaceImage.fromRgb(rgbBuf, width, height);
  }

  /// Gets the [Pixel] color value at position ([x], [y]).
  Pixel getPixel(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      throw ValidationException('Pixel coordinates ($x, $y) out of image bounds ($width x $height)');
    }
    final index = y * rowStride + x * channels;
    switch (format) {
      case ImageFormat.rgb:
        return Pixel(buffer[index], buffer[index + 1], buffer[index + 2]);
      case ImageFormat.rgba:
        return Pixel(buffer[index], buffer[index + 1], buffer[index + 2], buffer[index + 3]);
      case ImageFormat.grayscale:
        return Pixel.gray(buffer[index]);
    }
  }

  /// Sets the [Pixel] color value at position ([x], [y]).
  void setPixel(int x, int y, Pixel pixel) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      throw ValidationException('Pixel coordinates ($x, $y) out of image bounds ($width x $height)');
    }
    final index = y * rowStride + x * channels;
    switch (format) {
      case ImageFormat.rgb:
        buffer[index] = pixel.r;
        buffer[index + 1] = pixel.g;
        buffer[index + 2] = pixel.b;
        break;
      case ImageFormat.rgba:
        buffer[index] = pixel.r;
        buffer[index + 1] = pixel.g;
        buffer[index + 2] = pixel.b;
        buffer[index + 3] = pixel.a;
        break;
      case ImageFormat.grayscale:
        buffer[index] = pixel.r;
        break;
    }
  }

  /// Creates a deep copy of this [FaceImage] and its buffer.
  FaceImage clone() {
    final clonedBuffer = Uint8List.fromList(buffer);
    return FaceImage._(
      width: width,
      height: height,
      format: format,
      buffer: clonedBuffer,
      channels: channels,
    );
  }

  @override
  String toString() => 'FaceImage(${width}x$height, $format, ${buffer.length} bytes)';
}
