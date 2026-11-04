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
  });

  int get endMs => startMs + durationMs;

  Color get color => Color(colorValue);

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
    );
  }
}
