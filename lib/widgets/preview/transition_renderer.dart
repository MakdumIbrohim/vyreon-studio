import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../models/timeline_clip.dart';

class HorizontalWipeClipper extends CustomClipper<Rect> {
  final double progress;
  HorizontalWipeClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(covariant HorizontalWipeClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

class PrimaryTransitionRenderer {
  static Widget build({
    required Project project,
    required TimelineClip activeClip,
    required int playhead,
    required Widget Function(TimelineClip clip) buildClipVisual,
  }) {
    final primaries = project.primaryClips;
    final index = primaries.indexWhere((c) => c.id == activeClip.id);
    final prevClip = index > 0 ? primaries[index - 1] : null;

    final transitionDuration = activeClip.transitionDurationMs;
    final transitionElapsed = playhead - activeClip.startMs;

    if (prevClip != null &&
        activeClip.transition != TransitionType.none &&
        transitionElapsed >= 0 &&
        transitionElapsed < transitionDuration) {
      final progress =
          (transitionElapsed / transitionDuration).clamp(0.0, 1.0);
      final prevWidget = buildClipVisual(prevClip);
      final currWidget = buildClipVisual(activeClip);

      switch (activeClip.transition) {
        case TransitionType.fade:
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(opacity: (1.0 - progress).clamp(0.0, 1.0), child: prevWidget),
              Opacity(opacity: progress, child: currWidget),
            ],
          );
        case TransitionType.slideUp:
          return Stack(
            fit: StackFit.expand,
            children: [
              prevWidget,
              FractionalTranslation(
                translation: Offset(0, 1.0 - progress),
                child: currWidget,
              ),
            ],
          );
        case TransitionType.wipeLeft:
          return Stack(
            fit: StackFit.expand,
            children: [
              prevWidget,
              ClipRect(
                clipper: HorizontalWipeClipper(progress),
                child: currWidget,
              ),
            ],
          );
        case TransitionType.zoom:
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                  opacity: (1.0 - progress).clamp(0.0, 1.0),
                  child: prevWidget),
              Transform.scale(
                scale: 0.5 + (0.5 * progress),
                child: Opacity(opacity: progress, child: currWidget),
              ),
            ],
          );
        case TransitionType.none:
          return currWidget;
      }
    }

    return buildClipVisual(activeClip);
  }
}
