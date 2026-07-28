import 'dart:math' as math;
import '../core/facekit_exception.dart';
import 'tensor.dart';
import 'vector.dart';

/// Neural network mathematical operations including Conv2D, Pooling, and Activations.
abstract class MathOperations {
  /// 2D Convolution operation over a 3D [Tensor] input `[Channels, Height, Width]`
  /// using kernel `[OutChannels, InChannels, KernelHeight, KernelWidth]`.
  static Tensor conv2d(
    Tensor input,
    Tensor kernel, {
    int stride = 1,
    int padding = 0,
    Vector? bias,
  }) {
    if (input.shape.length != 3) {
      throw ValidationException('Conv2D input tensor must be 3D [Channels, Height, Width], got ${input.shape}');
    }
    if (kernel.shape.length != 4) {
      throw ValidationException(
        'Conv2D kernel tensor must be 4D [OutChannels, InChannels, KernelHeight, KernelWidth], got ${kernel.shape}',
      );
    }

    final inC = input.shape[0];
    final inH = input.shape[1];
    final inW = input.shape[2];

    final outC = kernel.shape[0];
    final kInC = kernel.shape[1];
    final kH = kernel.shape[2];
    final kW = kernel.shape[3];

    if (inC != kInC) {
      throw ValidationException(
        'Kernel input channels ($kInC) does not match input image channels ($inC)',
      );
    }
    if (bias != null && bias.length != outC) {
      throw ValidationException('Bias length (${bias.length}) must match OutChannels ($outC)');
    }

    final outH = ((inH - kH + 2 * padding) ~/ stride) + 1;
    final outW = ((inW - kW + 2 * padding) ~/ stride) + 1;

    if (outH <= 0 || outW <= 0) {
      throw ValidationException('Invalid output dimensions for Conv2D: $outH x $outW');
    }

    final output = Tensor([outC, outH, outW]);

    for (var co = 0; co < outC; co++) {
      final bVal = bias != null ? bias[co] : 0.0;
      for (var oh = 0; oh < outH; oh++) {
        final ihBase = oh * stride - padding;
        for (var ow = 0; ow < outW; ow++) {
          final iwBase = ow * stride - padding;
          double sum = bVal;

          for (var ci = 0; ci < inC; ci++) {
            for (var kh = 0; kh < kH; kh++) {
              final ih = ihBase + kh;
              if (ih < 0 || ih >= inH) continue;

              for (var kw = 0; kw < kW; kw++) {
                final iw = iwBase + kw;
                if (iw < 0 || iw >= inW) continue;

                sum += input.get3D(ci, ih, iw) * kernel.get4D(co, ci, kh, kw);
              }
            }
          }
          output.set3D(co, oh, ow, sum);
        }
      }
    }
    return output;
  }

  /// 2D Max Pooling operation over a 3D [Tensor] `[Channels, Height, Width]`.
  static Tensor maxPool2d(
    Tensor input, {
    int poolSize = 2,
    int stride = 2,
  }) {
    if (input.shape.length != 3) {
      throw const ValidationException('MaxPool2D input tensor must be 3D [Channels, Height, Width]');
    }

    final inC = input.shape[0];
    final inH = input.shape[1];
    final inW = input.shape[2];

    final outH = ((inH - poolSize) ~/ stride) + 1;
    final outW = ((inW - poolSize) ~/ stride) + 1;

    if (outH <= 0 || outW <= 0) {
      throw ValidationException('Invalid output dimensions for MaxPool2D: $outH x $outW');
    }

    final output = Tensor([inC, outH, outW]);

    for (var c = 0; c < inC; c++) {
      for (var oh = 0; oh < outH; oh++) {
        final ihBase = oh * stride;
        for (var ow = 0; ow < outW; ow++) {
          final iwBase = ow * stride;
          double maxVal = double.negativeInfinity;

          for (var ph = 0; ph < poolSize; ph++) {
            final ih = ihBase + ph;
            for (var pw = 0; pw < poolSize; pw++) {
              final iw = iwBase + pw;
              final val = input.get3D(c, ih, iw);
              if (val > maxVal) {
                maxVal = val;
              }
            }
          }
          output.set3D(c, oh, ow, maxVal);
        }
      }
    }
    return output;
  }

  /// 2D Average Pooling operation over a 3D [Tensor] `[Channels, Height, Width]`.
  static Tensor avgPool2d(
    Tensor input, {
    int poolSize = 2,
    int stride = 2,
  }) {
    if (input.shape.length != 3) {
      throw const ValidationException('AvgPool2D input tensor must be 3D [Channels, Height, Width]');
    }

    final inC = input.shape[0];
    final inH = input.shape[1];
    final inW = input.shape[2];

    final outH = ((inH - poolSize) ~/ stride) + 1;
    final outW = ((inW - poolSize) ~/ stride) + 1;

    if (outH <= 0 || outW <= 0) {
      throw ValidationException('Invalid output dimensions for AvgPool2D: $outH x $outW');
    }

    final output = Tensor([inC, outH, outW]);
    final poolArea = (poolSize * poolSize).toDouble();

    for (var c = 0; c < inC; c++) {
      for (var oh = 0; oh < outH; oh++) {
        final ihBase = oh * stride;
        for (var ow = 0; ow < outW; ow++) {
          final iwBase = ow * stride;
          double sum = 0.0;

          for (var ph = 0; ph < poolSize; ph++) {
            final ih = ihBase + ph;
            for (var pw = 0; pw < poolSize; pw++) {
              final iw = iwBase + pw;
              sum += input.get3D(c, ih, iw);
            }
          }
          output.set3D(c, oh, ow, sum / poolArea);
        }
      }
    }
    return output;
  }

  /// Rectified Linear Unit (ReLU) activation: max(0, x).
  static void reluInPlace(Tensor tensor) {
    final data = tensor.data;
    final len = data.length;
    for (var i = 0; i < len; i++) {
      if (data[i] < 0.0) {
        data[i] = 0.0;
      }
    }
  }

  /// Returns a new [Tensor] with ReLU applied.
  static Tensor relu(Tensor tensor) {
    final copy = tensor.clone();
    reluInPlace(copy);
    return copy;
  }

  /// LeakyReLU activation: x >= 0 ? x : alpha * x.
  static void leakyReluInPlace(Tensor tensor, {double alpha = 0.01}) {
    final data = tensor.data;
    final len = data.length;
    for (var i = 0; i < len; i++) {
      if (data[i] < 0.0) {
        data[i] = data[i] * alpha;
      }
    }
  }

  /// Sigmoid activation: 1 / (1 + exp(-x)).
  static Tensor sigmoid(Tensor tensor) {
    final result = tensor.clone();
    final data = result.data;
    final len = data.length;
    for (var i = 0; i < len; i++) {
      data[i] = 1.0 / (1.0 + math.exp(-data[i]));
    }
    return result;
  }

  /// Tanh activation: (exp(x) - exp(-x)) / (exp(x) + exp(-x)).
  static Tensor tanh(Tensor tensor) {
    final result = tensor.clone();
    final data = result.data;
    final len = data.length;
    for (var i = 0; i < len; i++) {
      final eX = math.exp(data[i]);
      final eNegX = math.exp(-data[i]);
      data[i] = (eX - eNegX) / (eX + eNegX);
    }
    return result;
  }

  /// Softmax activation over a 1D [Vector] with max-subtraction trick for numerical stability.
  static Vector softmax(Vector vector) {
    final n = vector.length;
    final result = Vector(n);

    double maxVal = double.negativeInfinity;
    for (var i = 0; i < n; i++) {
      if (vector[i] > maxVal) {
        maxVal = vector[i];
      }
    }

    double sumExp = 0.0;
    for (var i = 0; i < n; i++) {
      final expVal = math.exp(vector[i] - maxVal);
      result[i] = expVal;
      sumExp += expVal;
    }

    final invSum = 1.0 / sumExp;
    for (var i = 0; i < n; i++) {
      result[i] = result[i] * invSum;
    }

    return result;
  }
}
