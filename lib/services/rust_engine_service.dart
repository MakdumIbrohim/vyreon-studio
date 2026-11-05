import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'rust/rust_ffi_bindings.dart';

class RustEngineService {
  static final RustEngineService instance = RustEngineService._internal();
  factory RustEngineService() => instance;
  RustEngineService._internal() {
    _initLibrary();
  }

  ffi.DynamicLibrary? _lib;
  VersionDart? _versionFn;
  WaveformDart? _waveformFn;
  BeatPeaksDart? _beatFn;
  LerpTransformDart? _lerpFn;
  ChromaDart? _chromaFn;
  ColorGradeDart? _colorGradeFn;
  ApplyLutDart? _applyLutFn;
  AudioDspPcm16Dart? _dspPcm16Fn;
  AudioDspF32Dart? _dspF32Fn;

  bool get isAvailable => _lib != null;

  void _initLibrary() {
    _lib = RustFfiBindings.loadLibrary();
    if (_lib != null) {
      try {
        _versionFn = _lib!.lookupFunction<VersionC, VersionDart>('vyreon_rust_version');
        _waveformFn = _lib!.lookupFunction<WaveformC, WaveformDart>('vyreon_extract_waveform_peaks');
        _beatFn = _lib!.lookupFunction<BeatPeaksC, BeatPeaksDart>('vyreon_detect_beat_peaks');
        _lerpFn = _lib!.lookupFunction<LerpTransformC, LerpTransformDart>('vyreon_lerp_transform');
        _chromaFn = _lib!.lookupFunction<ChromaC, ChromaDart>('vyreon_chroma_key_alpha');
        _colorGradeFn = _lib!.lookupFunction<ColorGradeC, ColorGradeDart>('vyreon_color_grade_rgba');
        _applyLutFn = _lib!.lookupFunction<ApplyLutC, ApplyLutDart>('vyreon_apply_lut_3d_rgba');
        _dspPcm16Fn = _lib!.lookupFunction<AudioDspPcm16C, AudioDspPcm16Dart>('vyreon_audio_dsp_process_pcm16');
        _dspF32Fn = _lib!.lookupFunction<AudioDspF32C, AudioDspF32Dart>('vyreon_audio_dsp_process_f32');
      } catch (_) {
        // Partial load fallback
      }
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
      _lerpFn!(t, startScale, endScale, startX, endX, startY, endY, outScale, outX, outY);
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
    if (_chromaFn == null) return null;
    try {
      return _chromaFn!(r, g, b, keyR, keyG, keyB, threshold, smoothness);
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
    if (_colorGradeFn == null || pixels.isEmpty || (pixels.length % 4) != 0) return null;

    final ptr = malloc<ffi.Uint8>(pixels.length);
    try {
      final list = ptr.asTypedList(pixels.length);
      list.setAll(0, pixels);
      final code = _colorGradeFn!(ptr, pixels.length, brightness, contrast, saturation, temperature, tint);
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
    if (_applyLutFn == null || pixels.isEmpty || lutTable.isEmpty || lutSize < 2) return null;

    final pixPtr = malloc<ffi.Uint8>(pixels.length);
    final lutPtr = malloc<ffi.Float>(lutTable.length);
    try {
      final pixList = pixPtr.asTypedList(pixels.length);
      pixList.setAll(0, pixels);
      final lutList = lutPtr.asTypedList(lutTable.length);
      lutList.setAll(0, lutTable);

      final code = _applyLutFn!(pixPtr, pixels.length, lutPtr, lutSize, intensity);
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

  /// Real-time 16-bit PCM Audio DSP Processing (Volume, Noise Gate, Rumble Filter)
  Int16List? processAudioPcm16(
    Int16List samples, {
    double volume = 1.0,
    double noiseGateThreshold = 0.0,
    bool enableHighpass = false,
  }) {
    if (_dspPcm16Fn == null || samples.isEmpty) return null;

    final ptr = malloc<ffi.Int16>(samples.length);
    try {
      final list = ptr.asTypedList(samples.length);
      list.setAll(0, samples);
      final code = _dspPcm16Fn!(
        ptr,
        samples.length,
        volume,
        noiseGateThreshold,
        enableHighpass ? 1 : 0,
      );
      if (code == 0) {
        return Int16List.fromList(list);
      }
    } catch (_) {
      return null;
    } finally {
      malloc.free(ptr);
    }
    return null;
  }

  /// Real-time Float32 PCM Audio DSP Processing
  Float32List? processAudioF32(
    Float32List samples, {
    double volume = 1.0,
    double noiseGateThreshold = 0.0,
  }) {
    if (_dspF32Fn == null || samples.isEmpty) return null;

    final ptr = malloc<ffi.Float>(samples.length);
    try {
      final list = ptr.asTypedList(samples.length);
      list.setAll(0, samples);
      final code = _dspF32Fn!(ptr, samples.length, volume, noiseGateThreshold);
      if (code == 0) {
        return Float32List.fromList(list);
      }
    } catch (_) {
      return null;
    } finally {
      malloc.free(ptr);
    }
    return null;
  }
}
