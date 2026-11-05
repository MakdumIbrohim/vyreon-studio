import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'rust_ffi_bindings.dart';

mixin RustVisualOps {
  LerpTransformDart? get lerpFn;
  ChromaDart? get chromaFn;
  ColorGradeDart? get colorGradeFn;
  ApplyLutDart? get applyLutFn;
  BezierEvalDart? get bezierFn;
  BezierBatchDart? get bezierBatchFn;
  BlendLayersDart? get blendLayersFn;

  /// Rust-accelerated lerp transform
  ({double scale, double offsetX, double offsetY})? lerpTransform({
    required double t,
    required double startScale,
    required double endScale,
    required double startX,
    required double endX,
    required double startY,
    required double endY,
  }) {
    if (lerpFn == null) return null;

    final outScale = malloc<ffi.Float>();
    final outX = malloc<ffi.Float>();
    final outY = malloc<ffi.Float>();

    try {
      lerpFn!(t, startScale, endScale, startX, endX, startY, endY, outScale, outX, outY);
      return (scale: outScale.value, offsetX: outX.value, offsetY: outY.value);
    } catch (_) {
      return null;
    } finally {
      malloc.free(outScale);
      malloc.free(outX);
      malloc.free(outY);
    }
  }

  /// Rust-accelerated Chroma Key calculation
  int? chromaKeyAlpha({
    required int r,
    required int g,
    required int b,
    required int keyR,
    required int keyG,
    required int keyB,
    required double threshold,
    required double smoothness,
  }) {
    if (chromaFn == null) return null;
    try {
      return chromaFn!(r, g, b, keyR, keyG, keyB, threshold, smoothness);
    } catch (_) {
      return null;
    }
  }

  /// Rust-accelerated RGBA Color Grading (Brightness, Contrast, Saturation, Temp, Tint)
  Uint8List? colorGradeRgba(
    Uint8List pixels, {
    double brightness = 0.0,
    double contrast = 0.0,
    double saturation = 1.0,
    double temperature = 0.0,
    double tint = 0.0,
  }) {
    if (colorGradeFn == null || pixels.isEmpty || (pixels.length % 4) != 0) return null;

    final ptr = malloc<ffi.Uint8>(pixels.length);
    try {
      final list = ptr.asTypedList(pixels.length);
      list.setAll(0, pixels);
      final code = colorGradeFn!(ptr, pixels.length, brightness, contrast, saturation, temperature, tint);
      if (code == 0) {
        return Uint8List.fromList(list);
      }
    } catch (_) {
      return null;
    } finally {
      malloc.free(ptr);
    }
    return null;
  }

  /// Rust-accelerated 3D LUT Application
  Uint8List? applyLut3dRgba(Uint8List pixels, Float32List lutTable, int lutSize, {double intensity = 1.0}) {
    if (applyLutFn == null || pixels.isEmpty || lutTable.isEmpty || lutSize < 2) return null;

    final pixPtr = malloc<ffi.Uint8>(pixels.length);
    final lutPtr = malloc<ffi.Float>(lutTable.length);
    try {
      final pixList = pixPtr.asTypedList(pixels.length);
      pixList.setAll(0, pixels);
      final lutList = lutPtr.asTypedList(lutTable.length);
      lutList.setAll(0, lutTable);

      final code = applyLutFn!(pixPtr, pixels.length, lutPtr, lutSize, intensity);
      if (code == 0) {
        return Uint8List.fromList(pixList);
      }
    } catch (_) {
      return null;
    } finally {
      malloc.free(pixPtr);
      malloc.free(lutPtr);
    }
    return null;
  }

  /// Evaluates a single cubic-bezier easing curve value for x in [0.0, 1.0]
  double evaluateBezier(double x, {double x1 = 0.25, double y1 = 0.1, double x2 = 0.25, double y2 = 1.0}) {
    if (bezierFn == null) return x.clamp(0.0, 1.0);
    try {
      return bezierFn!(x, x1, y1, x2, y2);
    } catch (_) {
      return x.clamp(0.0, 1.0);
    }
  }

  /// Batch evaluates cubic bezier speed curve on an array of timestamps
  Float32List? evaluateSpeedCurveBatch(
    Float32List times, {
    double x1 = 0.25,
    double y1 = 0.1,
    double x2 = 0.25,
    double y2 = 1.0,
  }) {
    if (bezierBatchFn == null || times.isEmpty) return null;

    final inPtr = malloc<ffi.Float>(times.length);
    final outPtr = malloc<ffi.Float>(times.length);
    try {
      final inList = inPtr.asTypedList(times.length);
      inList.setAll(0, times);

      final code = bezierBatchFn!(inPtr, outPtr, times.length, x1, y1, x2, y2);
      if (code == 0) {
        final outList = outPtr.asTypedList(times.length);
        return Float32List.fromList(outList);
      }
    } catch (_) {
      return null;
    } finally {
      malloc.free(inPtr);
      malloc.free(outPtr);
    }
    return null;
  }

  /// Rust-accelerated Layer Pixel Blending (Normal, Multiply, Screen, Overlay, etc.)
  Uint8List? blendLayersRgba(
    Uint8List dstPixels,
    Uint8List srcPixels, {
    int blendMode = 0,
    double opacity = 1.0,
  }) {
    if (blendLayersFn == null || dstPixels.isEmpty || srcPixels.isEmpty || dstPixels.length != srcPixels.length) {
      return null;
    }

    final dstPtr = malloc<ffi.Uint8>(dstPixels.length);
    final srcPtr = malloc<ffi.Uint8>(srcPixels.length);
    try {
      final dstList = dstPtr.asTypedList(dstPixels.length);
      dstList.setAll(0, dstPixels);
      final srcList = srcPtr.asTypedList(srcPixels.length);
      srcList.setAll(0, srcPixels);

      final code = blendLayersFn!(dstPtr, srcPtr, dstPixels.length, blendMode, opacity);
      if (code == 0) {
        return Uint8List.fromList(dstList);
      }
    } catch (_) {
      return null;
    } finally {
      malloc.free(dstPtr);
      malloc.free(srcPtr);
    }
    return null;
  }
}
