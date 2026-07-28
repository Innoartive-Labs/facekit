import 'dart:math' as math;
import 'dart:typed_data';
import '../core/facekit_exception.dart';
import '../math/tensor.dart';
import 'face_image.dart';

/// Pure Dart computer vision and image processing engine.
abstract class ImageProcessor {
  /// Bilinear resize transformation.
  static FaceImage resizeBilinear(FaceImage src, int targetWidth, int targetHeight) {
    if (targetWidth <= 0 || targetHeight <= 0) {
      throw ValidationException('Target dimensions must be positive: $targetWidth x $targetHeight');
    }
    if (src.width == targetWidth && src.height == targetHeight) {
      return src.clone();
    }

    final srcW = src.width;
    final srcH = src.height;
    final channels = src.channels;
    final dstBuf = Uint8List(targetWidth * targetHeight * channels);

    final scaleX = srcW / targetWidth;
    final scaleY = srcH / targetHeight;
    final srcRowStride = src.rowStride;
    final srcBuf = src.buffer;

    var dstIdx = 0;

    for (var dy = 0; dy < targetHeight; dy++) {
      final rawSrcY = (dy + 0.5) * scaleY - 0.5;
      final srcY = rawSrcY.clamp(0.0, (srcH - 1).toDouble());
      final y0 = srcY.floor();
      final y1 = (y0 + 1).clamp(0, srcH - 1);
      final wy = srcY - y0;

      final offY0 = y0 * srcRowStride;
      final offY1 = y1 * srcRowStride;

      for (var dx = 0; dx < targetWidth; dx++) {
        final rawSrcX = (dx + 0.5) * scaleX - 0.5;
        final srcX = rawSrcX.clamp(0.0, (srcW - 1).toDouble());
        final x0 = srcX.floor();
        final x1 = (x0 + 1).clamp(0, srcW - 1);
        final wx = srcX - x0;

        final w00 = (1.0 - wx) * (1.0 - wy);
        final w10 = wx * (1.0 - wy);
        final w01 = (1.0 - wx) * wy;
        final w11 = wx * wy;

        final idx00 = offY0 + x0 * channels;
        final idx10 = offY0 + x1 * channels;
        final idx01 = offY1 + x0 * channels;
        final idx11 = offY1 + x1 * channels;

        for (var c = 0; c < channels; c++) {
          final val = w00 * srcBuf[idx00 + c] +
              w10 * srcBuf[idx10 + c] +
              w01 * srcBuf[idx01 + c] +
              w11 * srcBuf[idx11 + c];
          dstBuf[dstIdx++] = val.round().clamp(0, 255);
        }
      }
    }

    switch (src.format) {
      case ImageFormat.rgb:
        return FaceImage.fromRgb(dstBuf, targetWidth, targetHeight);
      case ImageFormat.rgba:
        return FaceImage.fromRgba(dstBuf, targetWidth, targetHeight);
      case ImageFormat.grayscale:
        return FaceImage.fromGrayscale(dstBuf, targetWidth, targetHeight);
    }
  }

  /// Rotates an image around its center by [angleRadians] using inverse bilinear mapping.
  static FaceImage rotate(FaceImage src, double angleRadians, {Pixel fillColor = const Pixel(0, 0, 0)}) {
    if (angleRadians == 0.0) {
      return src.clone();
    }

    final w = src.width;
    final h = src.height;
    final channels = src.channels;
    final dstBuf = Uint8List(w * h * channels);

    final cosA = math.cos(angleRadians);
    final sinA = math.sin(angleRadians);

    final cx = (w - 1) / 2.0;
    final cy = (h - 1) / 2.0;

    final srcBuf = src.buffer;
    final srcRowStride = src.rowStride;
    var dstIdx = 0;

    for (var dy = 0; dy < h; dy++) {
      final yDiff = dy - cy;
      for (var dx = 0; dx < w; dx++) {
        final xDiff = dx - cx;

        final srcX = cosA * xDiff + sinA * yDiff + cx;
        final srcY = -sinA * xDiff + cosA * yDiff + cy;

        if (srcX >= 0 && srcX < w && srcY >= 0 && srcY < h) {
          final clampedX = srcX.clamp(0.0, (w - 1).toDouble());
          final clampedY = srcY.clamp(0.0, (h - 1).toDouble());
          final x0 = clampedX.floor();
          final x1 = (x0 + 1).clamp(0, w - 1);
          final y0 = clampedY.floor();
          final y1 = (y0 + 1).clamp(0, h - 1);

          final wx = clampedX - x0;
          final wy = clampedY - y0;

          final offY0 = y0 * srcRowStride;
          final offY1 = y1 * srcRowStride;

          final idx00 = offY0 + x0 * channels;
          final idx10 = offY0 + x1 * channels;
          final idx01 = offY1 + x0 * channels;
          final idx11 = offY1 + x1 * channels;

          for (var c = 0; c < channels; c++) {
            final val = (1 - wx) * (1 - wy) * srcBuf[idx00 + c] +
                wx * (1 - wy) * srcBuf[idx10 + c] +
                (1 - wx) * wy * srcBuf[idx01 + c] +
                wx * wy * srcBuf[idx11 + c];
            dstBuf[dstIdx++] = val.round().clamp(0, 255);
          }
        } else {
          // Fill background color
          dstBuf[dstIdx++] = fillColor.r;
          if (channels >= 3) {
            dstBuf[dstIdx++] = fillColor.g;
            dstBuf[dstIdx++] = fillColor.b;
          }
          if (channels == 4) {
            dstBuf[dstIdx++] = fillColor.a;
          }
        }
      }
    }

    switch (src.format) {
      case ImageFormat.rgb:
        return FaceImage.fromRgb(dstBuf, w, h);
      case ImageFormat.rgba:
        return FaceImage.fromRgba(dstBuf, w, h);
      case ImageFormat.grayscale:
        return FaceImage.fromGrayscale(dstBuf, w, h);
    }
  }

  /// Extracts a sub-rectangle region from an image.
  static FaceImage crop(FaceImage src, int x, int y, int cropWidth, int cropHeight) {
    if (cropWidth <= 0 || cropHeight <= 0) {
      throw ValidationException('Crop size must be positive: $cropWidth x $cropHeight');
    }
    if (x < 0 || y < 0 || x + cropWidth > src.width || y + cropHeight > src.height) {
      throw ValidationException('Crop rectangle ($x, $y, $cropWidth, $cropHeight) out of image bounds (${src.width} x ${src.height})');
    }

    final channels = src.channels;
    final dstBuf = Uint8List(cropWidth * cropHeight * channels);
    final srcBuf = src.buffer;
    final srcRowStride = src.rowStride;
    final dstRowStride = cropWidth * channels;

    for (var r = 0; r < cropHeight; r++) {
      final srcOff = (y + r) * srcRowStride + x * channels;
      final dstOff = r * dstRowStride;
      dstBuf.setRange(dstOff, dstOff + dstRowStride, srcBuf, srcOff);
    }

    switch (src.format) {
      case ImageFormat.rgb:
        return FaceImage.fromRgb(dstBuf, cropWidth, cropHeight);
      case ImageFormat.rgba:
        return FaceImage.fromRgba(dstBuf, cropWidth, cropHeight);
      case ImageFormat.grayscale:
        return FaceImage.fromGrayscale(dstBuf, cropWidth, cropHeight);
    }
  }

  /// Adds border padding around an image.
  static FaceImage pad(
    FaceImage src,
    int top,
    int bottom,
    int left,
    int right, {
    Pixel fillColor = const Pixel(0, 0, 0),
  }) {
    if (top < 0 || bottom < 0 || left < 0 || right < 0) {
      throw const ValidationException('Padding amounts cannot be negative');
    }

    final outW = src.width + left + right;
    final outH = src.height + top + bottom;
    final channels = src.channels;
    final dstBuf = Uint8List(outW * outH * channels);

    // Pre-fill background
    var idx = 0;
    final totalPixels = outW * outH;
    for (var i = 0; i < totalPixels; i++) {
      dstBuf[idx++] = fillColor.r;
      if (channels >= 3) {
        dstBuf[idx++] = fillColor.g;
        dstBuf[idx++] = fillColor.b;
      }
      if (channels == 4) {
        dstBuf[idx++] = fillColor.a;
      }
    }

    // Copy original image into padded region
    final srcBuf = src.buffer;
    final srcRowStride = src.rowStride;
    final srcH = src.height;
    final copyLen = src.width * channels;

    for (var r = 0; r < srcH; r++) {
      final srcOff = r * srcRowStride;
      final dstOff = (top + r) * (outW * channels) + left * channels;
      dstBuf.setRange(dstOff, dstOff + copyLen, srcBuf, srcOff);
    }

    switch (src.format) {
      case ImageFormat.rgb:
        return FaceImage.fromRgb(dstBuf, outW, outH);
      case ImageFormat.rgba:
        return FaceImage.fromRgba(dstBuf, outW, outH);
      case ImageFormat.grayscale:
        return FaceImage.fromGrayscale(dstBuf, outW, outH);
    }
  }

  /// Contrast enhancement via Histogram Equalization on a Grayscale image.
  static FaceImage histogramEqualization(FaceImage src) {
    final gray = src.format == ImageFormat.grayscale ? src : src.toGrayscale();
    final w = gray.width;
    final h = gray.height;
    final totalPixels = w * h;
    final buf = gray.buffer;

    // 1. Calculate 256-bin histogram
    final hist = Int32List(256);
    for (var i = 0; i < totalPixels; i++) {
      hist[buf[i]]++;
    }

    // 2. Compute CDF (Cumulative Distribution Function)
    final cdf = Int32List(256);
    var accum = 0;
    var minCdf = 0;
    var foundMin = false;

    for (var i = 0; i < 256; i++) {
      accum += hist[i];
      cdf[i] = accum;
      if (!foundMin && accum > 0) {
        minCdf = accum;
        foundMin = true;
      }
    }

    // 3. Map equalized pixel values
    final dstBuf = Uint8List(totalPixels);
    final denom = totalPixels - minCdf;
    if (denom <= 0) {
      return gray.clone();
    }

    final lut = Uint8List(256);
    for (var i = 0; i < 256; i++) {
      lut[i] = (((cdf[i] - minCdf) / denom) * 255.0).round().clamp(0, 255);
    }

    for (var i = 0; i < totalPixels; i++) {
      dstBuf[i] = lut[buf[i]];
    }

    return FaceImage.fromGrayscale(dstBuf, w, h);
  }

  /// Separable Gaussian Spatial Smoothing Blur.
  static FaceImage gaussianBlur(FaceImage src, {int kernelSize = 5, double sigma = 1.0}) {
    if (kernelSize % 2 == 0 || kernelSize < 3) {
      throw ValidationException('Gaussian kernel size must be an odd integer >= 3, got $kernelSize');
    }

    final radius = kernelSize ~/ 2;
    final kernel = Float32List(kernelSize);
    double sum = 0.0;

    for (var i = -radius; i <= radius; i++) {
      final val = math.exp(-(i * i) / (2 * sigma * sigma));
      kernel[i + radius] = val;
      sum += val;
    }
    for (var i = 0; i < kernelSize; i++) {
      kernel[i] /= sum;
    }

    final gray = src.format == ImageFormat.grayscale ? src : src.toGrayscale();
    final w = gray.width;
    final h = gray.height;
    final srcBuf = gray.buffer;

    // Pass 1: Horizontal Blur
    final tempBuf = Float32List(w * h);
    for (var y = 0; y < h; y++) {
      final rowOff = y * w;
      for (var x = 0; x < w; x++) {
        double acc = 0.0;
        for (var k = -radius; k <= radius; k++) {
          final px = (x + k).clamp(0, w - 1);
          acc += srcBuf[rowOff + px] * kernel[k + radius];
        }
        tempBuf[rowOff + x] = acc;
      }
    }

    // Pass 2: Vertical Blur
    final dstBuf = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      final rowOff = y * w;
      for (var x = 0; x < w; x++) {
        double acc = 0.0;
        for (var k = -radius; k <= radius; k++) {
          final py = (y + k).clamp(0, h - 1);
          acc += tempBuf[py * w + x] * kernel[k + radius];
        }
        dstBuf[rowOff + x] = acc.round().clamp(0, 255);
      }
    }

    return FaceImage.fromGrayscale(dstBuf, w, h);
  }

  /// Sobel Edge Detection gradient magnitude filter ($G = \sqrt{G_x^2 + G_y^2}$).
  static FaceImage sobelEdgeDetection(FaceImage src) {
    final gray = src.format == ImageFormat.grayscale ? src : src.toGrayscale();
    final w = gray.width;
    final h = gray.height;
    final srcBuf = gray.buffer;
    final dstBuf = Uint8List(w * h);

    for (var y = 1; y < h - 1; y++) {
      final r0 = (y - 1) * w;
      final r1 = y * w;
      final r2 = (y + 1) * w;

      for (var x = 1; x < w - 1; x++) {
        final gx = -srcBuf[r0 + x - 1] + srcBuf[r0 + x + 1] -
            2 * srcBuf[r1 + x - 1] + 2 * srcBuf[r1 + x + 1] -
            srcBuf[r2 + x - 1] + srcBuf[r2 + x + 1];

        final gy = -srcBuf[r0 + x - 1] - 2 * srcBuf[r0 + x] - srcBuf[r0 + x + 1] +
            srcBuf[r2 + x - 1] + 2 * srcBuf[r2 + x] + srcBuf[r2 + x + 1];

        final mag = math.sqrt(gx * gx + gy * gy).round().clamp(0, 255);
        dstBuf[r1 + x] = mag;
      }
    }

    return FaceImage.fromGrayscale(dstBuf, w, h);
  }

  /// Converts a [FaceImage] into a 3D neural input [Tensor] `[Channels, Height, Width]`.
  static Tensor toTensor(
    FaceImage src, {
    bool normalizeZeroToOne = true,
    bool standardize = false,
  }) {
    final w = src.width;
    final h = src.height;
    final c = src.channels;
    final tensor = Tensor([c, h, w]);
    final buf = src.buffer;

    final scale = normalizeZeroToOne ? 1.0 / 255.0 : 1.0;

    var srcIdx = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        for (var ch = 0; ch < c; ch++) {
          tensor.set3D(ch, y, x, buf[srcIdx++] * scale);
        }
      }
    }

    if (standardize) {
      final data = tensor.data;
      final total = data.length;
      double sum = 0.0;
      for (var i = 0; i < total; i++) {
        sum += data[i];
      }
      final mean = sum / total;

      double varSum = 0.0;
      for (var i = 0; i < total; i++) {
        final diff = data[i] - mean;
        varSum += diff * diff;
      }
      final std = math.sqrt(varSum / total) + 1e-7;

      for (var i = 0; i < total; i++) {
        data[i] = (data[i] - mean) / std;
      }
    }

    return tensor;
  }

  /// Computes Local Binary Pattern (LBP) image encoding texture details.
  static Uint8List computeLbpMap(FaceImage src) {
    final gray = src.format == ImageFormat.grayscale ? src : src.toGrayscale();
    final w = gray.width;
    final h = gray.height;
    final srcBuf = gray.buffer;
    final lbpMap = Uint8List(w * h);

    for (var y = 1; y < h - 1; y++) {
      final r0 = (y - 1) * w;
      final r1 = y * w;
      final r2 = (y + 1) * w;

      for (var x = 1; x < w - 1; x++) {
        final center = srcBuf[r1 + x];
        var code = 0;

        if (srcBuf[r0 + x - 1] >= center) code |= 1 << 7;
        if (srcBuf[r0 + x] >= center) code |= 1 << 6;
        if (srcBuf[r0 + x + 1] >= center) code |= 1 << 5;
        if (srcBuf[r1 + x + 1] >= center) code |= 1 << 4;
        if (srcBuf[r2 + x + 1] >= center) code |= 1 << 3;
        if (srcBuf[r2 + x] >= center) code |= 1 << 2;
        if (srcBuf[r2 + x - 1] >= center) code |= 1 << 1;
        if (srcBuf[r1 + x - 1] >= center) code |= 1 << 0;

        lbpMap[r1 + x] = code;
      }
    }

    return lbpMap;
  }

  /// Extracts 128-dimensional spatial grid facial feature descriptor (16 cells x 8 features).
  static Float32List computeSpatialFeatureVector(FaceImage src) {
    final gray = src.format == ImageFormat.grayscale ? src : src.toGrayscale();
    final w = gray.width;
    final h = gray.height;
    final grayBuf = gray.buffer;
    final totalPixels = w * h;

    // Compute global mean and standard deviation
    double globalSum = 0.0;
    for (var i = 0; i < totalPixels; i++) {
      globalSum += grayBuf[i];
    }
    final globalMean = totalPixels > 0 ? globalSum / totalPixels : 128.0;

    final lbpMap = computeLbpMap(gray);

    // Compute HOG gradients
    final mag = Float32List(totalPixels);
    final angleBin = Uint8List(totalPixels);

    for (var y = 1; y < h - 1; y++) {
      final r0 = (y - 1) * w;
      final r1 = y * w;
      final r2 = (y + 1) * w;

      for (var x = 1; x < w - 1; x++) {
        final dx = (grayBuf[r1 + x + 1] - grayBuf[r1 + x - 1]).toDouble();
        final dy = (grayBuf[r2 + x] - grayBuf[r0 + x]).toDouble();
        final idx = r1 + x;
        mag[idx] = math.sqrt(dx * dx + dy * dy);

        double ang = math.atan2(dy, dx);
        if (ang < 0) ang += math.pi;
        angleBin[idx] = ((ang / math.pi) * 4).floor().clamp(0, 3);
      }
    }

    final features = Float32List(128);
    var featIdx = 0;

    // 4x4 Grid (16 Cells, 8 features per cell = 128 total features)
    const gridSize = 4;
    final cellW = w / gridSize;
    final cellH = h / gridSize;

    for (var gy = 0; gy < gridSize; gy++) {
      final startY = (gy * cellH).floor();
      final endY = ((gy + 1) * cellH).floor().clamp(0, h);

      for (var gx = 0; gx < gridSize; gx++) {
        final startX = (gx * cellW).floor();
        final endX = ((gx + 1) * cellW).floor().clamp(0, w);

        double cellSum = 0.0;
        var count = 0;
        final lbpBins = Float32List(4);
        final hogBins = Float32List(2);

        for (var y = startY; y < endY; y++) {
          final rowOff = y * w;
          for (var x = startX; x < endX; x++) {
            final idx = rowOff + x;
            cellSum += grayBuf[idx];
            count++;

            final lbpCode = lbpMap[idx];
            final lbpBin = (lbpCode >> 6) & 0x03;
            lbpBins[lbpBin] += 1.0;

            final hBin = angleBin[idx];
            if (hBin == 0 || hBin == 2) {
              hogBins[0] += mag[idx]; // Horizontal gradient component
            } else {
              hogBins[1] += mag[idx]; // Vertical gradient component
            }
          }
        }

        final cellMean = count > 0 ? cellSum / count : 0.0;

        double varSum = 0.0;
        for (var y = startY; y < endY; y++) {
          final rowOff = y * w;
          for (var x = startX; x < endX; x++) {
            final diff = grayBuf[rowOff + x] - cellMean;
            varSum += diff * diff;
          }
        }
        final cellStd = count > 0 ? math.sqrt(varSum / count) : 0.0;

        // Feature 1 & 2: Relative Mean & Std
        features[featIdx++] = ((cellMean - globalMean) / 64.0).clamp(-2.0, 2.0);
        features[featIdx++] = (cellStd / 32.0).clamp(0.0, 2.0);

        // Feature 3..6: Cell LBP histogram (L1 normalized)
        final lbpTotal = count > 0 ? count.toDouble() : 1.0;
        for (var i = 0; i < 4; i++) {
          features[featIdx++] = lbpBins[i] / lbpTotal;
        }

        // Feature 7..8: Cell HOG histogram (L2 normalized)
        final hogMagSum = math.sqrt(hogBins[0] * hogBins[0] + hogBins[1] * hogBins[1]) + 1e-7;
        features[featIdx++] = hogBins[0] / hogMagSum;
        features[featIdx++] = hogBins[1] / hogMagSum;
      }
    }

    // Mean-center the 128D feature vector
    double featSum = 0.0;
    for (var i = 0; i < 128; i++) {
      featSum += features[i];
    }
    final featMean = featSum / 128.0;

    for (var i = 0; i < 128; i++) {
      features[i] -= featMean;
    }

    return features;
  }



}

