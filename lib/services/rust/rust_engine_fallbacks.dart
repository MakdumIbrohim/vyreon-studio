class RustEngineFallbacks {
  /// Dart VM fallback for beat transient detection when Rust is unavailable
  static List<int> detectBeatPeaks({
    required List<double> peaks,
    required int durationMs,
    double thresholdMultiplier = 1.25,
    int maxBeats = 120,
  }) {
    if (peaks.length < 4 || durationMs <= 0 || maxBeats <= 0) return const [];

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
}
