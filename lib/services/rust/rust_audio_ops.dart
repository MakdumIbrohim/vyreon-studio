import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'rust_engine_fallbacks.dart';
import 'rust_ffi_bindings.dart';

mixin RustAudioOps {
  WaveformDart? get waveformFn;
  BeatPeaksDart? get beatFn;
  AudioDspPcm16Dart? get dspPcm16Fn;
  AudioDspF32Dart? get dspF32Fn;

  /// High-performance audio waveform peak extraction accelerated by Rust
  List<double>? extractWaveformPeaks(Uint8List bytes, int targetSamples) {
    if (waveformFn == null || bytes.isEmpty || targetSamples <= 0) return null;

    final dataPtr = malloc<ffi.Uint8>(bytes.length);
    final outPtr = malloc<ffi.Float>(targetSamples);

    try {
      final byteList = dataPtr.asTypedList(bytes.length);
      byteList.setAll(0, bytes);

      final code = waveformFn!(dataPtr, bytes.length, targetSamples, outPtr);
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

    if (beatFn != null) {
      final peaksPtr = malloc<ffi.Float>(peaks.length);
      final outPtr = malloc<ffi.Uint32>(maxBeats);

      try {
        final floatList = peaksPtr.asTypedList(peaks.length);
        floatList.setAll(0, peaks);

        final count = beatFn!(
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

    return RustEngineFallbacks.detectBeatPeaks(
      peaks: peaks,
      durationMs: durationMs,
      thresholdMultiplier: thresholdMultiplier,
      maxBeats: maxBeats,
    );
  }

  /// Real-time 16-bit PCM Audio DSP Processing (Volume, Noise Gate, Rumble Filter)
  Int16List? processAudioPcm16(
    Int16List samples, {
    double volume = 1.0,
    double noiseGateThreshold = 0.0,
    bool enableHighpass = false,
  }) {
    if (dspPcm16Fn == null || samples.isEmpty) return null;

    final ptr = malloc<ffi.Int16>(samples.length);
    try {
      final list = ptr.asTypedList(samples.length);
      list.setAll(0, samples);
      final code = dspPcm16Fn!(
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
    if (dspF32Fn == null || samples.isEmpty) return null;

    final ptr = malloc<ffi.Float>(samples.length);
    try {
      final list = ptr.asTypedList(samples.length);
      list.setAll(0, samples);
      final code = dspF32Fn!(ptr, samples.length, volume, noiseGateThreshold);
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
