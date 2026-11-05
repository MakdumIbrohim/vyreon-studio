class Keyframe {
  final int timeMs; // relative time inside clip (0 to durationMs)
  final double scale;
  final double rotation;
  final double offsetX;
  final double offsetY;
  final double opacity;

  const Keyframe({
    required this.timeMs,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.opacity = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'timeMs': timeMs,
    'scale': scale,
    'rotation': rotation,
    'offsetX': offsetX,
    'offsetY': offsetY,
    'opacity': opacity,
  };

  factory Keyframe.fromJson(Map<String, dynamic> json) {
    return Keyframe(
      timeMs: (json['timeMs'] as num).toInt(),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class InterpolatedTransform {
  final double scale;
  final double rotation;
  final double offsetX;
  final double offsetY;
  final double opacity;

  const InterpolatedTransform({
    required this.scale,
    required this.rotation,
    required this.offsetX,
    required this.offsetY,
    required this.opacity,
  });
}
