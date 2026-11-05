import 'dart:math';
import '../../models/timeline_clip.dart';

class LayerEvaluatedTransform {
  final double scale;
  final double rotation;
  final double opacity;
  final double offsetX;
  final double offsetY;

  const LayerEvaluatedTransform({
    required this.scale,
    required this.rotation,
    required this.opacity,
    required this.offsetX,
    required this.offsetY,
  });
}

class LayerAnimationEvaluator {
  static LayerEvaluatedTransform evaluate({
    required TimelineClip layer,
    required int playheadMs,
    required InterpolatedTransform baseTransform,
  }) {
    final relMs = (playheadMs - layer.startMs).clamp(0, layer.durationMs);

    // 1. In-Animation
    double inOpacity = 1.0;
    double inScale = 1.0;
    double inOffsetX = 0.0;
    double inOffsetY = 0.0;
    if (layer.inAnimation != InAnimationType.none &&
        layer.inDurationMs > 0 &&
        relMs < layer.inDurationMs) {
      final p = (relMs / layer.inDurationMs).clamp(0.0, 1.0);
      switch (layer.inAnimation) {
        case InAnimationType.fadeIn:
          inOpacity = p;
          break;
        case InAnimationType.pop:
          inScale = (p * 1.15).clamp(0.0, 1.0);
          inOpacity = p;
          break;
        case InAnimationType.slideRight:
          inOffsetX = (1.0 - p) * -1.5;
          inOpacity = p;
          break;
        case InAnimationType.slideLeft:
          inOffsetX = (1.0 - p) * 1.5;
          inOpacity = p;
          break;
        case InAnimationType.slideUp:
          inOffsetY = (1.0 - p) * 1.5;
          inOpacity = p;
          break;
        case InAnimationType.slideDown:
          inOffsetY = (1.0 - p) * -1.5;
          inOpacity = p;
          break;
        case InAnimationType.drop:
          inOffsetY = (1.0 - p) * -2.0;
          inScale = 0.8 + (p * 0.2);
          break;
        case InAnimationType.scaleUp:
          inScale = p * p;
          inOpacity = p;
          break;
        case InAnimationType.none:
          break;
      }
    }

    // 2. Out-Animation
    double outOpacity = 1.0;
    double outScale = 1.0;
    double outOffsetX = 0.0;
    double outOffsetY = 0.0;
    final outStartMs = layer.durationMs - layer.outDurationMs;
    if (layer.outAnimation != OutAnimationType.none &&
        layer.outDurationMs > 0 &&
        relMs > outStartMs) {
      final p = ((relMs - outStartMs) / layer.outDurationMs).clamp(0.0, 1.0);
      switch (layer.outAnimation) {
        case OutAnimationType.fadeOut:
          outOpacity = 1.0 - p;
          break;
        case OutAnimationType.popDown:
          outScale = 1.0 - (p * 0.8);
          outOpacity = 1.0 - p;
          break;
        case OutAnimationType.slideRight:
          outOffsetX = p * 1.5;
          outOpacity = 1.0 - p;
          break;
        case OutAnimationType.slideLeft:
          outOffsetX = p * -1.5;
          outOpacity = 1.0 - p;
          break;
        case OutAnimationType.slideUp:
          outOffsetY = p * -1.5;
          outOpacity = 1.0 - p;
          break;
        case OutAnimationType.slideDown:
          outOffsetY = p * 1.5;
          outOpacity = 1.0 - p;
          break;
        case OutAnimationType.scaleDown:
          outScale = (1.0 - p).clamp(0.0, 1.0);
          outOpacity = 1.0 - p;
          break;
        case OutAnimationType.none:
          break;
      }
    }

    // 3. Overall-Animation
    double overallScale = 1.0;
    double overallRotation = 0.0;
    double overallOffsetX = 0.0;
    double overallOffsetY = 0.0;
    double overallOpacity = 1.0;
    if (layer.overallAnimation != OverallAnimationType.none) {
      final t = relMs / 1000.0;
      switch (layer.overallAnimation) {
        case OverallAnimationType.blinkSlow:
          overallOpacity = (sin(t * 3) > 0) ? 1.0 : 0.3;
          break;
        case OverallAnimationType.pulse:
          overallScale = 1.0 + (sin(t * 4).abs() * 0.15);
          break;
        case OverallAnimationType.jitter:
          overallOffsetX = sin(t * 25) * 0.05;
          overallOffsetY = cos(t * 25) * 0.05;
          break;
        case OverallAnimationType.floating:
          overallOffsetY = sin(t * 2) * 0.1;
          break;
        case OverallAnimationType.drifting:
          overallOffsetX = sin(t * 1.5) * 0.12;
          break;
        case OverallAnimationType.squishing:
          overallScale = 1.0 + (sin(t * 5) * 0.1);
          break;
        case OverallAnimationType.clockwiseSpin:
          overallRotation = (t * 120) % 360;
          break;
        case OverallAnimationType.counterClockwiseSpin:
          overallRotation = -(t * 120) % 360;
          break;
        case OverallAnimationType.none:
          break;
      }
    }

    final combinedScale =
        baseTransform.scale * inScale * outScale * overallScale;
    final combinedRotation = baseTransform.rotation + overallRotation;
    final combinedOpacity = (baseTransform.opacity *
            inOpacity *
            outOpacity *
            overallOpacity)
        .clamp(0.0, 1.0);
    final combinedOffsetX = (baseTransform.offsetX +
            inOffsetX +
            outOffsetX +
            overallOffsetX)
        .clamp(-2.0, 2.0);
    final combinedOffsetY = (baseTransform.offsetY +
            inOffsetY +
            outOffsetY +
            overallOffsetY)
        .clamp(-2.0, 2.0);

    return LayerEvaluatedTransform(
      scale: combinedScale,
      rotation: combinedRotation,
      opacity: combinedOpacity,
      offsetX: combinedOffsetX,
      offsetY: combinedOffsetY,
    );
  }
}
