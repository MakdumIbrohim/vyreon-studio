import 'package:flutter/material.dart';
import 'audio_presets.dart';
import 'clip_types.dart';
import 'keyframe.dart';
import 'layer_animations.dart';
import 'pan_zoom.dart';
import 'pip_presets.dart';
import 'speed_point.dart';
import 'transition_type.dart';
import 'volume_point.dart';
import 'crop_mask.dart';

export 'audio_presets.dart';
export 'clip_types.dart';
export 'crop_mask.dart';
export 'keyframe.dart';
export 'layer_animations.dart';
export 'pan_zoom.dart';
export 'pip_presets.dart';
export 'speed_point.dart';
export 'transition_type.dart';
export 'volume_point.dart';

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
  final List<SpeedPoint> speedPoints;
  final bool isVignetteEnabled;
  final double vignetteIntensity;
  final bool isTextOutlineEnabled;
  final int textOutlineColor;
  final double textOutlineWidth;
  final bool isTextShadowEnabled;
  final int textShadowColor;
  final double textShadowBlur;
  final bool isTextGlowEnabled;
  final int textGlowColor;
  final double textGlowRadius;
  final AudioEqPreset eqPreset;
  final VoiceChangerPreset voiceChanger;
  final List<double> waveformSamples;
  final PanZoomTransform panZoom;
  final PipPreset pipPreset;
  final InAnimationType inAnimation;
  final int inDurationMs;
  final OverallAnimationType overallAnimation;
  final OutAnimationType outAnimation;
  final int outDurationMs;
  final List<VolumePoint> volumeEnvelope;
  final bool isDuckingEnabled;
  final double duckingLevel;
  final ClipCropMask cropMask;
  final AudioReverbPreset reverbPreset;
  final String textAlign;
  final bool isTextBackgroundEnabled;
  final int textBackgroundColor;
  final double textBackgroundCornerRadius;
  final double textBackgroundPadding;
  final double letterSpacing;
  final double lineSpacing;

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
    this.speedPoints = const [],
    this.isVignetteEnabled = false,
    this.vignetteIntensity = 0.5,
    this.isTextOutlineEnabled = false,
    this.textOutlineColor = 0xFF000000,
    this.textOutlineWidth = 2.0,
    this.isTextShadowEnabled = false,
    this.textShadowColor = 0xAA000000,
    this.textShadowBlur = 6.0,
    this.isTextGlowEnabled = false,
    this.textGlowColor = 0xFFFFD700,
    this.textGlowRadius = 12.0,
    this.eqPreset = AudioEqPreset.normal,
    this.voiceChanger = VoiceChangerPreset.none,
    this.waveformSamples = const [],
    this.panZoom = const PanZoomTransform(),
    this.pipPreset = PipPreset.none,
    this.inAnimation = InAnimationType.none,
    this.inDurationMs = 1000,
    this.overallAnimation = OverallAnimationType.none,
    this.outAnimation = OutAnimationType.none,
    this.outDurationMs = 1000,
    this.volumeEnvelope = const [],
    this.isDuckingEnabled = false,
    this.duckingLevel = 0.25,
    this.cropMask = const ClipCropMask(),
    this.reverbPreset = AudioReverbPreset.none,
    this.textAlign = 'center',
    this.isTextBackgroundEnabled = false,
    this.textBackgroundColor = 0x80000000,
    this.textBackgroundCornerRadius = 6.0,
    this.textBackgroundPadding = 8.0,
    this.letterSpacing = 0.0,
    this.lineSpacing = 1.2,
  });

  int get endMs => startMs + durationMs;

  Color get color => Color(colorValue);

  double getEffectiveSpeedAt(double progress) {
    if (speedPoints.isEmpty) return speed;
    final p = progress.clamp(0.0, 1.0);
    final sorted = List<SpeedPoint>.from(speedPoints)
      ..sort((a, b) => a.position.compareTo(b.position));

    if (p <= sorted.first.position) return sorted.first.speed;
    if (p >= sorted.last.position) return sorted.last.speed;

    for (int i = 0; i < sorted.length - 1; i++) {
      final p1 = sorted[i];
      final p2 = sorted[i + 1];
      if (p >= p1.position && p <= p2.position) {
        final span = p2.position - p1.position;
        final t = span > 0 ? (p - p1.position) / span : 0.0;
        return p1.speed + (p2.speed - p1.speed) * t;
      }
    }
    return speed;
  }

  double getEffectiveVolumeAt(int relativeMs, {bool isDucked = false}) {
    if (isMuted) return 0.0;
    double base = volume;
    if (volumeEnvelope.isNotEmpty) {
      final sorted = List<VolumePoint>.from(volumeEnvelope)
        ..sort((a, b) => a.timeMs.compareTo(b.timeMs));
      if (relativeMs <= sorted.first.timeMs) {
        base = sorted.first.volume;
      } else if (relativeMs >= sorted.last.timeMs) {
        base = sorted.last.volume;
      } else {
        for (int i = 0; i < sorted.length - 1; i++) {
          final p1 = sorted[i];
          final p2 = sorted[i + 1];
          if (relativeMs >= p1.timeMs && relativeMs <= p2.timeMs) {
            final span = p2.timeMs - p1.timeMs;
            final t = span > 0 ? (relativeMs - p1.timeMs) / span : 0.0;
            base = p1.volume + (p2.volume - p1.volume) * t;
            break;
          }
        }
      }
    }
    if (isDucked) {
      base *= duckingLevel;
    }
    return base.clamp(0.0, 2.0);
  }

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
    List<SpeedPoint>? speedPoints,
    bool? isVignetteEnabled,
    double? vignetteIntensity,
    bool? isTextOutlineEnabled,
    int? textOutlineColor,
    double? textOutlineWidth,
    bool? isTextShadowEnabled,
    int? textShadowColor,
    double? textShadowBlur,
    bool? isTextGlowEnabled,
    int? textGlowColor,
    double? textGlowRadius,
    AudioEqPreset? eqPreset,
    VoiceChangerPreset? voiceChanger,
    List<double>? waveformSamples,
    PanZoomTransform? panZoom,
    PipPreset? pipPreset,
    InAnimationType? inAnimation,
    int? inDurationMs,
    OverallAnimationType? overallAnimation,
    OutAnimationType? outAnimation,
    int? outDurationMs,
    List<VolumePoint>? volumeEnvelope,
    bool? isDuckingEnabled,
    double? duckingLevel,
    ClipCropMask? cropMask,
    AudioReverbPreset? reverbPreset,
    String? textAlign,
    bool? isTextBackgroundEnabled,
    int? textBackgroundColor,
    double? textBackgroundCornerRadius,
    double? textBackgroundPadding,
    double? letterSpacing,
    double? lineSpacing,
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
      speedPoints: speedPoints ?? this.speedPoints,
      isVignetteEnabled: isVignetteEnabled ?? this.isVignetteEnabled,
      vignetteIntensity: vignetteIntensity ?? this.vignetteIntensity,
      isTextOutlineEnabled: isTextOutlineEnabled ?? this.isTextOutlineEnabled,
      textOutlineColor: textOutlineColor ?? this.textOutlineColor,
      textOutlineWidth: textOutlineWidth ?? this.textOutlineWidth,
      isTextShadowEnabled: isTextShadowEnabled ?? this.isTextShadowEnabled,
      textShadowColor: textShadowColor ?? this.textShadowColor,
      textShadowBlur: textShadowBlur ?? this.textShadowBlur,
      isTextGlowEnabled: isTextGlowEnabled ?? this.isTextGlowEnabled,
      textGlowColor: textGlowColor ?? this.textGlowColor,
      textGlowRadius: textGlowRadius ?? this.textGlowRadius,
      eqPreset: eqPreset ?? this.eqPreset,
      voiceChanger: voiceChanger ?? this.voiceChanger,
      waveformSamples: waveformSamples ?? this.waveformSamples,
      panZoom: panZoom ?? this.panZoom,
      pipPreset: pipPreset ?? this.pipPreset,
      inAnimation: inAnimation ?? this.inAnimation,
      inDurationMs: inDurationMs ?? this.inDurationMs,
      overallAnimation: overallAnimation ?? this.overallAnimation,
      outAnimation: outAnimation ?? this.outAnimation,
      outDurationMs: outDurationMs ?? this.outDurationMs,
      volumeEnvelope: volumeEnvelope ?? this.volumeEnvelope,
      isDuckingEnabled: isDuckingEnabled ?? this.isDuckingEnabled,
      duckingLevel: duckingLevel ?? this.duckingLevel,
      cropMask: cropMask ?? this.cropMask,
      reverbPreset: reverbPreset ?? this.reverbPreset,
      textAlign: textAlign ?? this.textAlign,
      isTextBackgroundEnabled:
          isTextBackgroundEnabled ?? this.isTextBackgroundEnabled,
      textBackgroundColor: textBackgroundColor ?? this.textBackgroundColor,
      textBackgroundCornerRadius:
          textBackgroundCornerRadius ?? this.textBackgroundCornerRadius,
      textBackgroundPadding:
          textBackgroundPadding ?? this.textBackgroundPadding,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineSpacing: lineSpacing ?? this.lineSpacing,
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
    'speedPoints': speedPoints.map((s) => s.toJson()).toList(),
    'isVignetteEnabled': isVignetteEnabled,
    'vignetteIntensity': vignetteIntensity,
    'isTextOutlineEnabled': isTextOutlineEnabled,
    'textOutlineColor': textOutlineColor,
    'textOutlineWidth': textOutlineWidth,
    'isTextShadowEnabled': isTextShadowEnabled,
    'textShadowColor': textShadowColor,
    'textShadowBlur': textShadowBlur,
    'isTextGlowEnabled': isTextGlowEnabled,
    'textGlowColor': textGlowColor,
    'textGlowRadius': textGlowRadius,
    'eqPreset': eqPreset.name,
    'voiceChanger': voiceChanger.name,
    'waveformSamples': waveformSamples,
    'panZoom': panZoom.toJson(),
    'pipPreset': pipPreset.name,
    'inAnimation': inAnimation.name,
    'inDurationMs': inDurationMs,
    'overallAnimation': overallAnimation.name,
    'outAnimation': outAnimation.name,
    'outDurationMs': outDurationMs,
    'volumeEnvelope': volumeEnvelope.map((v) => v.toJson()).toList(),
    'isDuckingEnabled': isDuckingEnabled,
    'duckingLevel': duckingLevel,
    'cropMask': cropMask.toJson(),
    'reverbPreset': reverbPreset.name,
    'textAlign': textAlign,
    'isTextBackgroundEnabled': isTextBackgroundEnabled,
    'textBackgroundColor': textBackgroundColor,
    'textBackgroundCornerRadius': textBackgroundCornerRadius,
    'textBackgroundPadding': textBackgroundPadding,
    'letterSpacing': letterSpacing,
    'lineSpacing': lineSpacing,
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
      speedPoints: (json['speedPoints'] as List<dynamic>?)
              ?.map((s) => SpeedPoint.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      isVignetteEnabled: json['isVignetteEnabled'] as bool? ?? false,
      vignetteIntensity:
          (json['vignetteIntensity'] as num?)?.toDouble() ?? 0.5,
      isTextOutlineEnabled: json['isTextOutlineEnabled'] as bool? ?? false,
      textOutlineColor:
          (json['textOutlineColor'] as num?)?.toInt() ?? 0xFF000000,
      textOutlineWidth:
          (json['textOutlineWidth'] as num?)?.toDouble() ?? 2.0,
      isTextShadowEnabled: json['isTextShadowEnabled'] as bool? ?? false,
      textShadowColor:
          (json['textShadowColor'] as num?)?.toInt() ?? 0xAA000000,
      textShadowBlur:
          (json['textShadowBlur'] as num?)?.toDouble() ?? 6.0,
      isTextGlowEnabled: json['isTextGlowEnabled'] as bool? ?? false,
      textGlowColor:
          (json['textGlowColor'] as num?)?.toInt() ?? 0xFFFFD700,
      textGlowRadius:
          (json['textGlowRadius'] as num?)?.toDouble() ?? 12.0,
      eqPreset: AudioEqPreset.values.firstWhere(
        (e) => e.name == json['eqPreset'],
        orElse: () => AudioEqPreset.normal,
      ),
      voiceChanger: VoiceChangerPreset.values.firstWhere(
        (e) => e.name == json['voiceChanger'],
        orElse: () => VoiceChangerPreset.none,
      ),
      waveformSamples: (json['waveformSamples'] as List<dynamic>?)
              ?.map((w) => (w as num).toDouble())
              .toList() ??
          const [],
      panZoom: json['panZoom'] != null
          ? PanZoomTransform.fromJson(json['panZoom'] as Map<String, dynamic>)
          : const PanZoomTransform(),
      pipPreset: PipPreset.values.firstWhere(
        (e) => e.name == json['pipPreset'],
        orElse: () => PipPreset.none,
      ),
      inAnimation: InAnimationType.values.firstWhere(
        (e) => e.name == json['inAnimation'],
        orElse: () => InAnimationType.none,
      ),
      inDurationMs: (json['inDurationMs'] as num?)?.toInt() ?? 1000,
      overallAnimation: OverallAnimationType.values.firstWhere(
        (e) => e.name == json['overallAnimation'],
        orElse: () => OverallAnimationType.none,
      ),
      outAnimation: OutAnimationType.values.firstWhere(
        (e) => e.name == json['outAnimation'],
        orElse: () => OutAnimationType.none,
      ),
      outDurationMs: (json['outDurationMs'] as num?)?.toInt() ?? 1000,
      volumeEnvelope: (json['volumeEnvelope'] as List<dynamic>?)
              ?.map((v) => VolumePoint.fromJson(v as Map<String, dynamic>))
              .toList() ??
          const [],
      isDuckingEnabled: json['isDuckingEnabled'] as bool? ?? false,
      duckingLevel: (json['duckingLevel'] as num?)?.toDouble() ?? 0.25,
      cropMask: json['cropMask'] != null
          ? ClipCropMask.fromJson(json['cropMask'] as Map<String, dynamic>)
          : const ClipCropMask(),
      reverbPreset: AudioReverbPreset.values.firstWhere(
        (e) => e.name == json['reverbPreset'],
        orElse: () => AudioReverbPreset.none,
      ),
      textAlign: json['textAlign'] as String? ?? 'center',
      isTextBackgroundEnabled:
          json['isTextBackgroundEnabled'] as bool? ?? false,
      textBackgroundColor:
          (json['textBackgroundColor'] as num?)?.toInt() ?? 0x80000000,
      textBackgroundCornerRadius:
          (json['textBackgroundCornerRadius'] as num?)?.toDouble() ?? 6.0,
      textBackgroundPadding:
          (json['textBackgroundPadding'] as num?)?.toDouble() ?? 8.0,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      lineSpacing: (json['lineSpacing'] as num?)?.toDouble() ?? 1.2,
    );
  }
}
