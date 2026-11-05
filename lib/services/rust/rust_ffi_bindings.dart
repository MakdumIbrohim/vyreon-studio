import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

// Version
typedef VersionC = ffi.Pointer<Utf8> Function();
typedef VersionDart = ffi.Pointer<Utf8> Function();

// Audio Waveform
typedef WaveformC = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8> dataPtr,
  ffi.Size dataLen,
  ffi.Size targetSamples,
  ffi.Pointer<ffi.Float> outPtr,
);
typedef WaveformDart = int Function(
  ffi.Pointer<ffi.Uint8> dataPtr,
  int dataLen,
  int targetSamples,
  ffi.Pointer<ffi.Float> outPtr,
);

// Beat Peaks
typedef BeatPeaksC = ffi.Int32 Function(
  ffi.Pointer<ffi.Float> peaksPtr,
  ffi.Size peaksLen,
  ffi.Uint32 durationMs,
  ffi.Float thresholdMultiplier,
  ffi.Pointer<ffi.Uint32> outMsPtr,
  ffi.Size maxBeats,
);
typedef BeatPeaksDart = int Function(
  ffi.Pointer<ffi.Float> peaksPtr,
  int peaksLen,
  int durationMs,
  double thresholdMultiplier,
  ffi.Pointer<ffi.Uint32> outMsPtr,
  int maxBeats,
);

// Lerp Transform
typedef LerpTransformC = ffi.Void Function(
  ffi.Float t,
  ffi.Float startScale,
  ffi.Float endScale,
  ffi.Float startX,
  ffi.Float endX,
  ffi.Float startY,
  ffi.Float endY,
  ffi.Pointer<ffi.Float> outScale,
  ffi.Pointer<ffi.Float> outX,
  ffi.Pointer<ffi.Float> outY,
);
typedef LerpTransformDart = void Function(
  double t,
  double startScale,
  double endScale,
  double startX,
  double endX,
  double startY,
  double endY,
  ffi.Pointer<ffi.Float> outScale,
  ffi.Pointer<ffi.Float> outX,
  ffi.Pointer<ffi.Float> outY,
);

// Chroma Key
typedef ChromaC = ffi.Uint8 Function(
  ffi.Uint8 r,
  ffi.Uint8 g,
  ffi.Uint8 b,
  ffi.Uint8 keyR,
  ffi.Uint8 keyG,
  ffi.Uint8 keyB,
  ffi.Float threshold,
  ffi.Float smoothness,
);
typedef ChromaDart = int Function(
  int r,
  int g,
  int b,
  int keyR,
  int keyG,
  int keyB,
  double threshold,
  double smoothness,
);

// Color Grade RGBA
typedef ColorGradeC = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8> pixelsPtr,
  ffi.Size len,
  ffi.Float brightness,
  ffi.Float contrast,
  ffi.Float saturation,
  ffi.Float temperature,
  ffi.Float tint,
);
typedef ColorGradeDart = int Function(
  ffi.Pointer<ffi.Uint8> pixelsPtr,
  int len,
  double brightness,
  double contrast,
  double saturation,
  double temperature,
  double tint,
);

// 3D LUT RGBA
typedef ApplyLutC = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8> pixelsPtr,
  ffi.Size len,
  ffi.Pointer<ffi.Float> lutPtr,
  ffi.Size lutSize,
  ffi.Float intensity,
);
typedef ApplyLutDart = int Function(
  ffi.Pointer<ffi.Uint8> pixelsPtr,
  int len,
  ffi.Pointer<ffi.Float> lutPtr,
  int lutSize,
  double intensity,
);

// Audio DSP PCM16
typedef AudioDspPcm16C = ffi.Int32 Function(
  ffi.Pointer<ffi.Int16> samplesPtr,
  ffi.Size samplesLen,
  ffi.Float volume,
  ffi.Float noiseGateThreshold,
  ffi.Int32 enableHighpass,
);
typedef AudioDspPcm16Dart = int Function(
  ffi.Pointer<ffi.Int16> samplesPtr,
  int samplesLen,
  double volume,
  double noiseGateThreshold,
  int enableHighpass,
);

// Audio DSP Float32
typedef AudioDspF32C = ffi.Int32 Function(
  ffi.Pointer<ffi.Float> samplesPtr,
  ffi.Size samplesLen,
  ffi.Float volume,
  ffi.Float noiseGateThreshold,
);
typedef AudioDspF32Dart = int Function(
  ffi.Pointer<ffi.Float> samplesPtr,
  int samplesLen,
  double volume,
  double noiseGateThreshold,
);

// Bézier Easing & Speed Curve
typedef BezierEvalC = ffi.Float Function(
  ffi.Float x,
  ffi.Float x1,
  ffi.Float y1,
  ffi.Float x2,
  ffi.Float y2,
);
typedef BezierEvalDart = double Function(
  double x,
  double x1,
  double y1,
  double x2,
  double y2,
);

typedef BezierBatchC = ffi.Int32 Function(
  ffi.Pointer<ffi.Float> inTimesPtr,
  ffi.Pointer<ffi.Float> outValuesPtr,
  ffi.Size count,
  ffi.Float x1,
  ffi.Float y1,
  ffi.Float x2,
  ffi.Float y2,
);
typedef BezierBatchDart = int Function(
  ffi.Pointer<ffi.Float> inTimesPtr,
  ffi.Pointer<ffi.Float> outValuesPtr,
  int count,
  double x1,
  double y1,
  double x2,
  double y2,
);

// Layer Pixel Blending
typedef BlendLayersC = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8> dstPtr,
  ffi.Pointer<ffi.Uint8> srcPtr,
  ffi.Size len,
  ffi.Int32 mode,
  ffi.Float opacity,
);
typedef BlendLayersDart = int Function(
  ffi.Pointer<ffi.Uint8> dstPtr,
  ffi.Pointer<ffi.Uint8> srcPtr,
  int len,
  int mode,
  double opacity,
);

// SRT Parser
typedef ParseSrtC = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> srtPtr);
typedef ParseSrtDart = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> srtPtr);

typedef FreeStringC = ffi.Void Function(ffi.Pointer<Utf8> ptr);
typedef FreeStringDart = void Function(ffi.Pointer<Utf8> ptr);

class RustFfiBindings {
  static ffi.DynamicLibrary? loadLibrary() {
    try {
      if (Platform.isLinux) {
        final localCandidates = [
          'native/rust_engine/target/release/libvyreon_rust_engine.so',
          '${Directory.current.path}/native/rust_engine/target/release/libvyreon_rust_engine.so',
          'libvyreon_rust_engine.so',
        ];

        for (final path in localCandidates) {
          if (File(path).existsSync()) {
            return ffi.DynamicLibrary.open(path);
          }
        }
        return ffi.DynamicLibrary.open('libvyreon_rust_engine.so');
      } else if (Platform.isAndroid) {
        return ffi.DynamicLibrary.open('libvyreon_rust_engine.so');
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
