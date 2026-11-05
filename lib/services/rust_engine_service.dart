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
