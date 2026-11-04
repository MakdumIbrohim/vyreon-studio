import 'package:flutter/material.dart';

enum ClipType {
  video(Icons.videocam, 'Video'),
  image(Icons.image, 'Image'),
  color(Icons.palette, 'Solid Color'),
  text(Icons.title, 'Text'),
  audio(Icons.audiotrack, 'Audio'),
  sticker(Icons.auto_awesome, 'Graphic');

  final IconData icon;
  final String label;
  const ClipType(this.icon, this.label);
}

enum ColorFilterPreset {
  none('Normal'),
  warm('Warm'),
  cool('Cool'),
  vivid('Vivid'),
  mono('Monochrome'),
  vintage('Vintage'),
  cyberpunk('Cyberpunk');

  final String label;
  const ColorFilterPreset(this.label);
}

enum TransitionType {
  none('None / Cut', Icons.block),
  fade('Crossfade', Icons.blur_linear),
  wipeLeft('Wipe', Icons.swipe_left),
  slideUp('Slide Up', Icons.arrow_upward),
  zoom('Zoom Dissolve', Icons.zoom_in);

  final String label;
  final IconData icon;
  const TransitionType(this.label, this.icon);
}

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

class TimelineClip {
  final String id;
  final String name;
  final ClipType type;
  final int startMs;
  final int durationMs;
  final int sourceInMs;
  final int sourceDurationMs;
  final String? assetPath;
  final int colorValue; // ARGB
  final String textContent;
  final double fontSize;
  final double scale;
  final double rotation; // degrees
  final double offsetX;
  final double offsetY;
  final double opacity;
  final double brightness; // -100 to 100
  final double contrast; // -100 to 100
  final double saturation; // -100 to 100
  final ColorFilterPreset filter;
  final double volume; // 0.0 to 2.0
  final bool isMuted;
  final double speed;
  final bool isPrimary;
  final int trackIndex;
  final TransitionType transition;
  final int transitionDurationMs;
  final List<Keyframe> keyframes;
  final bool isChromaKeyEnabled;
  final int chromaKeyColor;
  final double chromaThreshold;
  final double chromaSmoothness;
  final bool chromaShowMask;

  const TimelineClip({
    required this.id,
    required this.name,
    required this.type,
    required this.startMs,
    required this.durationMs,
    this.sourceInMs = 0,
    required this.sourceDurationMs,
    this.assetPath,
    this.colorValue = 0xFF2196F3,
    this.textContent = 'Sample Text',
    this.fontSize = 28.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.opacity = 1.0,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.filter = ColorFilterPreset.none,
    this.volume = 1.0,
    this.isMuted = false,
    this.speed = 1.0,
    this.isPrimary = true,
    this.trackIndex = 0,
    this.transition = TransitionType.none,
    this.transitionDurationMs = 1000,
    this.keyframes = const [],
    this.isChromaKeyEnabled = false,
    this.chromaKeyColor = 0xFF00FF00,
    this.chromaThreshold = 0.35,
    this.chromaSmoothness = 0.1,
    this.chromaShowMask = false,
  });

  int get endMs => startMs + durationMs;

  Color get color => Color(colorValue);

  InterpolatedTransform getInterpolatedTransform(int currentPlayheadMs) {
    if (keyframes.isEmpty) {
      return InterpolatedTransform(
        scale: scale,
        rotation: rotation,
        offsetX: offsetX,
        offsetY: offsetY,
        opacity: opacity,
      );
    }

    final relMs = (currentPlayheadMs - startMs).clamp(0, durationMs);
    final sorted = List<Keyframe>.from(keyframes)
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));

    if (relMs <= sorted.first.timeMs) {
      final k = sorted.first;
      return InterpolatedTransform(
        scale: k.scale,
        rotation: k.rotation,
        offsetX: k.offsetX,
        offsetY: k.offsetY,
        opacity: k.opacity,
      );
    }

    if (relMs >= sorted.last.timeMs) {
      final k = sorted.last;
      return InterpolatedTransform(
        scale: k.scale,
        rotation: k.rotation,
        offsetX: k.offsetX,
        offsetY: k.offsetY,
        opacity: k.opacity,
      );
    }

    for (int i = 0; i < sorted.length - 1; i++) {
      final k1 = sorted[i];
      final k2 = sorted[i + 1];
      if (relMs >= k1.timeMs && relMs <= k2.timeMs) {
        final span = k2.timeMs - k1.timeMs;
        final t = span > 0 ? (relMs - k1.timeMs) / span : 0.0;
        return InterpolatedTransform(
          scale: k1.scale + (k2.scale - k1.scale) * t,
          rotation: k1.rotation + (k2.rotation - k1.rotation) * t,
          offsetX: k1.offsetX + (k2.offsetX - k1.offsetX) * t,
          offsetY: k1.offsetY + (k2.offsetY - k1.offsetY) * t,
          opacity: k1.opacity + (k2.opacity - k1.opacity) * t,
        );
      }
    }

    return InterpolatedTransform(
      scale: scale,
      rotation: rotation,
      offsetX: offsetX,
      offsetY: offsetY,
      opacity: opacity,
    );
  }

  TimelineClip copyWith({
    String? id,
    String? name,
    ClipType? type,
    int? startMs,
    int? durationMs,
    int? sourceInMs,
    int? sourceDurationMs,
    String? assetPath,
    int? colorValue,
    String? textContent,
    double? fontSize,
    double? scale,
    double? rotation,
    double? offsetX,
    double? offsetY,
    double? opacity,
    double? brightness,
    double? contrast,
    double? saturation,
    ColorFilterPreset? filter,
    double? volume,
    bool? isMuted,
    double? speed,
    bool? isPrimary,
    int? trackIndex,
    TransitionType? transition,
    int? transitionDurationMs,
    List<Keyframe>? keyframes,
    bool? isChromaKeyEnabled,
    int? chromaKeyColor,
    double? chromaThreshold,
    double? chromaSmoothness,
    bool? chromaShowMask,
  }) {
    return TimelineClip(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      startMs: startMs ?? this.startMs,
      durationMs: durationMs ?? this.durationMs,
      sourceInMs: sourceInMs ?? this.sourceInMs,
      sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
      assetPath: assetPath ?? this.assetPath,
      colorValue: colorValue ?? this.colorValue,
      textContent: textContent ?? this.textContent,
      fontSize: fontSize ?? this.fontSize,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      opacity: opacity ?? this.opacity,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      filter: filter ?? this.filter,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      speed: speed ?? this.speed,
      isPrimary: isPrimary ?? this.isPrimary,
      trackIndex: trackIndex ?? this.trackIndex,
      transition: transition ?? this.transition,
      transitionDurationMs:
          transitionDurationMs ?? this.transitionDurationMs,
      keyframes: keyframes ?? this.keyframes,
      isChromaKeyEnabled: isChromaKeyEnabled ?? this.isChromaKeyEnabled,
      chromaKeyColor: chromaKeyColor ?? this.chromaKeyColor,
      chromaThreshold: chromaThreshold ?? this.chromaThreshold,
      chromaSmoothness: chromaSmoothness ?? this.chromaSmoothness,
      chromaShowMask: chromaShowMask ?? this.chromaShowMask,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'startMs': startMs,
    'durationMs': durationMs,
    'sourceInMs': sourceInMs,
    'sourceDurationMs': sourceDurationMs,
    'assetPath': assetPath,
    'colorValue': colorValue,
    'textContent': textContent,
    'fontSize': fontSize,
    'scale': scale,
    'rotation': rotation,
    'offsetX': offsetX,
    'offsetY': offsetY,
    'opacity': opacity,
    'brightness': brightness,
    'contrast': contrast,
    'saturation': saturation,
    'filter': filter.name,
    'volume': volume,
    'isMuted': isMuted,
    'speed': speed,
    'isPrimary': isPrimary,
    'trackIndex': trackIndex,
    'transition': transition.name,
    'transitionDurationMs': transitionDurationMs,
    'keyframes': keyframes.map((k) => k.toJson()).toList(),
    'isChromaKeyEnabled': isChromaKeyEnabled,
    'chromaKeyColor': chromaKeyColor,
    'chromaThreshold': chromaThreshold,
    'chromaSmoothness': chromaSmoothness,
    'chromaShowMask': chromaShowMask,
  };

  factory TimelineClip.fromJson(Map<String, dynamic> json) {
    return TimelineClip(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ClipType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ClipType.color,
      ),
      startMs: (json['startMs'] as num).toInt(),
      durationMs: (json['durationMs'] as num).toInt(),
      sourceInMs: (json['sourceInMs'] as num?)?.toInt() ?? 0,
      sourceDurationMs:
          (json['sourceDurationMs'] as num?)?.toInt() ??
          (json['durationMs'] as num).toInt(),
      assetPath: json['assetPath'] as String?,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF2196F3,
      textContent: json['textContent'] as String? ?? 'Sample Text',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 28.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 0.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 0.0,
      filter: ColorFilterPreset.values.firstWhere(
        (e) => e.name == json['filter'],
        orElse: () => ColorFilterPreset.none,
      ),
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      isMuted: json['isMuted'] as bool? ?? false,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      isPrimary: json['isPrimary'] as bool? ?? true,
      trackIndex: (json['trackIndex'] as num?)?.toInt() ?? 0,
      transition: TransitionType.values.firstWhere(
        (e) => e.name == json['transition'],
        orElse: () => TransitionType.none,
      ),
      transitionDurationMs:
          (json['transitionDurationMs'] as num?)?.toInt() ?? 1000,
      keyframes:
          (json['keyframes'] as List<dynamic>?)
              ?.map((k) => Keyframe.fromJson(k as Map<String, dynamic>))
              .toList() ??
          const [],
      isChromaKeyEnabled: json['isChromaKeyEnabled'] as bool? ?? false,
      chromaKeyColor: (json['chromaKeyColor'] as num?)?.toInt() ?? 0xFF00FF00,
      chromaThreshold:
          (json['chromaThreshold'] as num?)?.toDouble() ?? 0.35,
      chromaSmoothness:
          (json['chromaSmoothness'] as num?)?.toDouble() ?? 0.1,
      chromaShowMask: json['chromaShowMask'] as bool? ?? false,
    );
  }
}
