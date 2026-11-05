import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'rust_engine_service.dart';

class AudioWaveformService {
  static final AudioWaveformService _instance = AudioWaveformService._internal();
  factory AudioWaveformService() => _instance;
  AudioWaveformService._internal();

  final Map<String, List<double>> _cache = {};

  /// Generate or extract amplitude samples (normalized 0.0 to 1.0)
  Future<List<double>> getWaveformSamples({
    String? filePath,
    required String clipId,
    required int durationMs,
    int targetSampleCount = 100,
  }) async {
    final cacheKey = '$clipId-$durationMs-$targetSampleCount';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    List<double> samples;
    if (filePath != null && filePath.isNotEmpty && File(filePath).existsSync()) {
      samples = await _extractFromFile(filePath, targetSampleCount);
    } else {
      samples = _generateSyntheticBeatWaveform(clipId, durationMs, targetSampleCount);
    }

    _cache[cacheKey] = samples;
    return samples;
  }

  /// Fast byte-level peak sampler for local audio files (WAV, MP3, AAC, M4A)
  Future<List<double>> _extractFromFile(String filePath, int targetCount) async {
    try {
      final file = File(filePath);
      final length = await file.length();
      if (length < 1024) {
        return _generateSyntheticBeatWaveform(filePath, 5000, targetCount);
      }

      // 1. Rust-accelerated waveform extraction (Fast SIMD memory pass)
      if (RustEngineService.instance.isAvailable && length < 25 * 1024 * 1024) {
        final bytes = await file.readAsBytes();
        final rustPeaks =
            RustEngineService.instance.extractWaveformPeaks(bytes, targetCount);
        if (rustPeaks != null && rustPeaks.isNotEmpty) {
          return rustPeaks;
        }
      }

      // 2. Fallback byte-level decimation pass
      final randomAccess = await file.open(mode: FileMode.read);
      final step = (length / targetCount).floor();
      final List<double> result = [];

      for (int i = 0; i < targetCount; i++) {
        final position = (i * step).clamp(0, length - 64);
        await randomAccess.setPosition(position);
        final buffer = Uint8List(64);
        final readBytes = await randomAccess.readInto(buffer);
        if (readBytes <= 0) {
          result.add(0.2);
          continue;
        }

        // Calculate average amplitude deviation from mid-range byte (128)
        double sum = 0.0;
        for (int b = 0; b < readBytes; b++) {
          final diff = (buffer[b] - 128).abs();
          sum += diff;
        }
        final avg = (sum / (readBytes * 128)).clamp(0.08, 1.0);
        result.add(avg);
      }

      await randomAccess.close();

      // Normalize samples so peak is ~0.95
      final maxVal = result.fold<double>(0.1, (prev, elem) => max(prev, elem));
      return result.map((e) => ((e / maxVal) * 0.95).clamp(0.08, 1.0)).toList();
    } catch (_) {
      return _generateSyntheticBeatWaveform(filePath, 5000, targetCount);
    }
  }

  /// Generates rhythmic musical peaks with beats, drops, and dynamic variation
  List<double> _generateSyntheticBeatWaveform(String seedStr, int durationMs, int count) {
    final seed = seedStr.codeUnits.fold<int>(0, (p, c) => p + c);
    final rnd = Random(seed);

    final List<double> samples = [];
    final tempoBeats = (durationMs / 450.0).clamp(4.0, 64.0); // simulated BPM

    for (int i = 0; i < count; i++) {
      final progress = i / count;
      final beatPhase = (progress * tempoBeats * 2 * pi);

      // Bass kick pulse
      final kick = (sin(beatPhase) > 0.7) ? 0.85 : 0.2;
      // High-hat / snare modulation
      final snare = (cos(beatPhase * 2) > 0.85) ? 0.7 : 0.15;
      // Ambient noise
      final jitter = rnd.nextDouble() * 0.2;

      final val = ((kick * 0.6 + snare * 0.4 + jitter)).clamp(0.1, 0.95);
      samples.add(val);
    }

    return samples;
  }
}
