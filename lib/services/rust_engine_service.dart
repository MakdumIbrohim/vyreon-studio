import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

// C Signatures
typedef _VersionC = ffi.Pointer<Utf8> Function();
typedef _VersionDart = ffi.Pointer<Utf8> Function();

typedef _WaveformC = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8> dataPtr,
  ffi.Size dataLen,
  ffi.Size targetSamples,
  ffi.Pointer<ffi.Float> outPtr,
);
typedef _WaveformDart = int Function(
  ffi.Pointer<ffi.Uint8> dataPtr,
  int dataLen,
  int targetSamples,
  ffi.Pointer<ffi.Float> outPtr,
);

typedef _BeatPeaksC = ffi.Int32 Function(
  ffi.Pointer<ffi.Float> peaksPtr,
  ffi.Size peaksLen,
  ffi.Uint32 durationMs,
  ffi.Float thresholdMultiplier,
  ffi.Pointer<ffi.Uint32> outMsPtr,
  ffi.Size maxBeats,
);
typedef _BeatPeaksDart = int Function(
  ffi.Pointer<ffi.Float> peaksPtr,
  int peaksLen,
  int durationMs,
  double thresholdMultiplier,
  ffi.Pointer<ffi.Uint32> outMsPtr,
  int maxBeats,
);

typedef _LerpTransformC = ffi.Void Function(
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
typedef _LerpTransformDart = void Function(
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

typedef _ChromaC = ffi.Uint8 Function(
  ffi.Uint8 r,
  ffi.Uint8 g,
  ffi.Uint8 b,
  ffi.Uint8 keyR,
  ffi.Uint8 keyG,
  ffi.Uint8 keyB,
  ffi.Float threshold,
  ffi.Float smoothness,
);
typedef _ChromaDart = int Function(
  int r,
  int g,
  int b,
  int keyR,
  int keyG,
  int keyB,
  double threshold,
  double smoothness,
);

class RustEngineService {
  static final RustEngineService instance = RustEngineService._internal();
  factory RustEngineService() => instance;
  RustEngineService._internal() {
    _initLibrary();
  }

  ffi.DynamicLibrary? _lib;
  _VersionDart? _versionFn;
  _WaveformDart? _waveformFn;
  _BeatPeaksDart? _beatFn;
  _LerpTransformDart? _lerpFn;
  _ChromaDart? _chromaFn;

  bool get isAvailable => _lib != null;

  void _initLibrary() {
    try {
      if (Platform.isLinux) {
        final localCandidates = [
          'native/rust_engine/target/release/libvyreon_rust_engine.so',
          '${Directory.current.path}/native/rust_engine/target/release/libvyreon_rust_engine.so',
          'libvyreon_rust_engine.so',
        ];

        for (final path in localCandidates) {
          if (File(path).existsSync()) {
            _lib = ffi.DynamicLibrary.open(path);
            break;
          }
        }
        _lib ??= ffi.DynamicLibrary.open('libvyreon_rust_engine.so');
      } else if (Platform.isAndroid) {
        _lib = ffi.DynamicLibrary.open('libvyreon_rust_engine.so');
      }

      if (_lib != null) {
        _versionFn = _lib!
            .lookupFunction<_VersionC, _VersionDart>('vyreon_rust_version');
        _waveformFn = _lib!.lookupFunction<_WaveformC, _WaveformDart>(
            'vyreon_extract_waveform_peaks');
        _beatFn = _lib!.lookupFunction<_BeatPeaksC, _BeatPeaksDart>(
            'vyreon_detect_beat_peaks');
        _lerpFn = _lib!.lookupFunction<_LerpTransformC, _LerpTransformDart>(
            'vyreon_lerp_transform');
        _chromaFn = _lib!.lookupFunction<_ChromaC, _ChromaDart>(
            'vyreon_chroma_key_alpha');
      }
    } catch (_) {
      _lib = null;
    }
  }

  String get version {
    if (_versionFn == null) return 'Dart VM Fallback Engine';
    try {
      final ptr = _versionFn!();
      return ptr.toDartString();
    } catch (_) {
      return 'Dart VM Fallback Engine';
    }
  }

  /// High-performance audio waveform peak extraction accelerated by Rust
  List<double>? extractWaveformPeaks(Uint8List bytes, int targetSamples) {
    if (_waveformFn == null || bytes.isEmpty || targetSamples <= 0) return null;

    final dataPtr = malloc<ffi.Uint8>(bytes.length);
    final outPtr = malloc<ffi.Float>(targetSamples);

    try {
      final byteList = dataPtr.asTypedList(bytes.length);
      byteList.setAll(0, bytes);

      final code = _waveformFn!(dataPtr, bytes.length, targetSamples, outPtr);
      if (code == 0) {
        final floatList = outPtr.asTypedList(targetSamples);
        return List<double>.from(floatList);
      }
    } catch (_) {
      return null;
    } finally {
      malloc.free(dataPtr);
      malloc.free(outPtr);
    }
    return null;
  }

  /// High-performance rhythmic beat transient peak detection accelerated by Rust
  List<int> detectBeatPeaks({
    required List<double> peaks,
    required int durationMs,
    double thresholdMultiplier = 1.25,
    int maxBeats = 120,
  }) {
    if (peaks.length < 4 || durationMs <= 0 || maxBeats <= 0) return const [];

    if (_beatFn != null) {
      final peaksPtr = malloc<ffi.Float>(peaks.length);
      final outPtr = malloc<ffi.Uint32>(maxBeats);

      try {
        final floatList = peaksPtr.asTypedList(peaks.length);
        floatList.setAll(0, peaks);

        final count = _beatFn!(
          peaksPtr,
          peaks.length,
          durationMs,
          thresholdMultiplier,
          outPtr,
          maxBeats,
        );

        if (count > 0) {
          final outList = outPtr.asTypedList(count);
          return List<int>.from(outList);
        }
      } catch (_) {
        // Fallback to Dart VM
      } finally {
        malloc.free(peaksPtr);
        malloc.free(outPtr);
      }
    }

    // Dart fallback
    final sum = peaks.reduce((a, b) => a + b);
    final mean = sum / peaks.length;
    final threshold = mean * thresholdMultiplier.clamp(1.05, 2.5);

    final beats = <int>[];
    final minDistance = (peaks.length / 40).clamp(2, 20).toInt();
    int lastBeatIdx = -100;

    for (int i = 1; i < peaks.length - 1; i++) {
      if (beats.length >= maxBeats) break;
      final curr = peaks[i];
      if (curr > threshold && curr >= peaks[i - 1] && curr >= peaks[i + 1]) {
        if (i - lastBeatIdx >= minDistance) {
          final timeMs = ((i / peaks.length) * durationMs).round();
          beats.add(timeMs);
          lastBeatIdx = i;
        }
      }
    }
    return beats;
  }

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
    if (_lerpFn == null) return null;

    final outScale = malloc<ffi.Float>();
    final outX = malloc<ffi.Float>();
    final outY = malloc<ffi.Float>();

    try {
      _lerpFn!(
        t,
        startScale,
        endScale,
        startX,
        endX,
        startY,
        endY,
        outScale,
        outX,
        outY,
      );
      return (
        scale: outScale.value,
        offsetX: outX.value,
        offsetY: outY.value,
      );
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
    if (_chromaFn == null) return null;
    try {
      return _chromaFn!(
        r,
        g,
        b,
        keyR,
        keyG,
        keyB,
        threshold,
        smoothness,
      );
    } catch (_) {
      return null;
    }
  }
}
