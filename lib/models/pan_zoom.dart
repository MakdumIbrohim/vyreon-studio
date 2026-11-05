import 'dart:ui';

class PanZoomTransform {
  final double startScale;
  final double startOffsetX;
  final double startOffsetY;
  final double endScale;
  final double endOffsetX;
  final double endOffsetY;
  final bool isEnabled;

  const PanZoomTransform({
    this.startScale = 1.0,
    this.startOffsetX = 0.0,
    this.startOffsetY = 0.0,
    this.endScale = 1.25,
    this.endOffsetX = 0.0,
    this.endOffsetY = 0.0,
    this.isEnabled = false,
  });

  PanZoomTransform copyWith({
    double? startScale,
    double? startOffsetX,
    double? startOffsetY,
    double? endScale,
    double? endOffsetX,
    double? endOffsetY,
    bool? isEnabled,
  }) {
    return PanZoomTransform(
      startScale: startScale ?? this.startScale,
      startOffsetX: startOffsetX ?? this.startOffsetX,
      startOffsetY: startOffsetY ?? this.startOffsetY,
      endScale: endScale ?? this.endScale,
      endOffsetX: endOffsetX ?? this.endOffsetX,
      endOffsetY: endOffsetY ?? this.endOffsetY,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'startScale': startScale,
    'startOffsetX': startOffsetX,
    'startOffsetY': startOffsetY,
    'endScale': endScale,
    'endOffsetX': endOffsetX,
    'endOffsetY': endOffsetY,
    'isEnabled': isEnabled,
  };

  factory PanZoomTransform.fromJson(Map<String, dynamic> json) {
    return PanZoomTransform(
      startScale: (json['startScale'] as num?)?.toDouble() ?? 1.0,
      startOffsetX: (json['startOffsetX'] as num?)?.toDouble() ?? 0.0,
      startOffsetY: (json['startOffsetY'] as num?)?.toDouble() ?? 0.0,
      endScale: (json['endScale'] as num?)?.toDouble() ?? 1.25,
      endOffsetX: (json['endOffsetX'] as num?)?.toDouble() ?? 0.0,
      endOffsetY: (json['endOffsetY'] as num?)?.toDouble() ?? 0.0,
      isEnabled: json['isEnabled'] as bool? ?? false,
    );
  }

  /// Interpolates scale & offset at progress [0.0 - 1.0]
  ({double scale, double offsetX, double offsetY}) lerpAt(double progress) {
    if (!isEnabled) {
      return (scale: 1.0, offsetX: 0.0, offsetY: 0.0);
    }
    final t = progress.clamp(0.0, 1.0);
    final s = lerpDouble(startScale, endScale, t) ?? 1.0;
    final ox = lerpDouble(startOffsetX, endOffsetX, t) ?? 0.0;
    final oy = lerpDouble(startOffsetY, endOffsetY, t) ?? 0.0;
    return (scale: s, offsetX: ox, offsetY: oy);
  }
}
