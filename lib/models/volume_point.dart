class VolumePoint {
  final int timeMs; // Relative to clip start
  final double volume; // 0.0 to 2.0 (1.0 = 100%)

  const VolumePoint({
    required this.timeMs,
    required this.volume,
  });

  VolumePoint copyWith({
    int? timeMs,
    double? volume,
  }) {
    return VolumePoint(
      timeMs: timeMs ?? this.timeMs,
      volume: volume ?? this.volume,
    );
  }

  Map<String, dynamic> toJson() => {
    'timeMs': timeMs,
    'volume': volume,
  };

  factory VolumePoint.fromJson(Map<String, dynamic> json) {
    return VolumePoint(
      timeMs: (json['timeMs'] as num).toInt(),
      volume: (json['volume'] as num).toDouble(),
    );
  }
}
