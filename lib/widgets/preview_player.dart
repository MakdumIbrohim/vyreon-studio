import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/timeline_clip.dart';
import '../services/video_thumbnail_service.dart';
import '../state/editor_controller.dart';
import '../theme/app_theme.dart';
import '../utils/color_filters.dart';
import 'preview/clip_pattern_painter.dart';
import 'preview/direct_manipulation_overlay.dart';
import 'preview/transition_renderer.dart';

class PreviewPlayer extends StatelessWidget {
  final EditorController controller;

  const PreviewPlayer({super.key, required this.controller});

  String _formatTimecode(int ms) {
    final totalSeconds = ms / 1000;
    final minutes = (totalSeconds / 60).floor();
    final seconds = (totalSeconds % 60).floor();
    final millis = ((ms % 1000) / 100).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final project = controller.project;
        final playhead = controller.playheadMs;
        final aspectRatio = project.aspectRatio.value;

        // Active primary clip
        TimelineClip? activePrimary;
        for (final c in project.primaryClips) {
          if (playhead >= c.startMs && playhead < c.endMs) {
            activePrimary = c;
            break;
          }
        }

        // Active secondary layers
        final activeSecondaries = project.secondaryClips.where((c) {
          return playhead >= c.startMs &&
              playhead < c.endMs &&
              c.type != ClipType.audio;
        }).toList();

        return Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Aspect ratio frame
              AspectRatio(
                aspectRatio: aspectRatio,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF181920),
                    border: Border.all(
                      color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Primary Track Background with Transition
                      if (activePrimary != null)
                        PrimaryTransitionRenderer.build(
                          project: project,
                          activeClip: activePrimary,
                          playhead: playhead,
                          buildClipVisual: _buildClipVisual,
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.movie_filter_outlined,
                                size: 48,
                                color: AppTheme.textMuted.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No Media at Current Time',
                                style: TextStyle(
                                  color:
                                      AppTheme.textMuted.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Secondary Overlay Layers
                      for (final layer in activeSecondaries)
                        _buildLayerVisual(layer, playhead),

                      // Interactive Direct Manipulation Handle (for selected layer)
                      if (controller.selectedClip != null &&
                          !controller.selectedClip!.isPrimary &&
                          activeSecondaries
                              .any((c) => c.id == controller.selectedClipId))
                        DirectManipulationOverlay(
                          controller: controller,
                          layer: controller.selectedClip!,
                          playheadMs: playhead,
                        ),
                    ],
                  ),
                ),
              ),

              // Timecode & Duration overlay (Top Right)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    '${_formatTimecode(controller.playheadMs)} / ${_formatTimecode(project.totalDurationMs)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),

              // Aspect ratio tag (Top Left)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        project.aspectRatio.icon,
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        project.aspectRatio.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClipVisual(TimelineClip clip) {
    final filter = ColorFilterHelper.getPresetFilter(clip.filter);

    Widget content;
    final file = clip.assetPath != null ? File(clip.assetPath!) : null;

    if (file != null && file.existsSync()) {
      if (clip.type == ClipType.image) {
        content = Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderVisual(clip),
        );
      } else {
        final relMs = (controller.playheadMs - clip.startMs)
            .clamp(0, clip.durationMs);
        content = FutureBuilder<File?>(
          future: VideoThumbnailService()
              .getThumbnailFile(clip.assetPath!, atMs: relMs),
          builder: (context, snapshot) {
            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!.existsSync()) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    snapshot.data!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => _buildVideoPlaceholder(clip),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam,
                              size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(clip.name,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return _buildVideoPlaceholder(clip);
          },
        );
      }
    } else {
      content = _buildPlaceholderVisual(clip);
    }

    if (filter != null) {
      content = ColorFiltered(colorFilter: filter, child: content);
    }

    if (clip.panZoom.isEnabled && clip.durationMs > 0) {
      final progress =
          ((controller.playheadMs - clip.startMs) / clip.durationMs)
              .clamp(0.0, 1.0);
      final pz = clip.panZoom.lerpAt(progress);
      content = Transform.translate(
        offset: Offset(pz.offsetX * 80, pz.offsetY * 80),
        child: Transform.scale(
          scale: pz.scale,
          child: content,
        ),
      );
    }

    if (clip.isVignetteEnabled) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.85,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(
                        alpha: clip.vignetteIntensity.clamp(0.0, 1.0)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Opacity(
      opacity: clip.opacity.clamp(0.0, 1.0),
      child: content,
    );
  }

  Widget _buildVideoPlaceholder(TimelineClip clip) {
    return Container(
      color: Colors.black87,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: ClipPatternPainter(clip.color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam, size: 48, color: Colors.white70),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  clip.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderVisual(TimelineClip clip) {
    return Container(
      color: clip.color,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: ClipPatternPainter(clip.color),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(clip.type.icon, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  clip.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerVisual(TimelineClip layer, int playheadMs) {
    final filter = ColorFilterHelper.getPresetFilter(layer.filter);
    final transform = layer.getInterpolatedTransform(playheadMs);

    Widget layerWidget;
    if (layer.type == ClipType.text) {
      final shadows = <Shadow>[];
      if (layer.isTextShadowEnabled) {
        shadows.add(
          Shadow(
            color: Color(layer.textShadowColor),
            blurRadius: layer.textShadowBlur,
            offset: const Offset(2, 2),
          ),
        );
      }
      if (layer.isTextGlowEnabled) {
        shadows.add(
          Shadow(
            color: Color(layer.textGlowColor),
            blurRadius: layer.textGlowRadius,
          ),
        );
      }
      if (shadows.isEmpty) {
        shadows.add(
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        );
      }

      final textMain = Text(
        layer.textContent,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: layer.color,
          fontSize: layer.fontSize,
          fontWeight: FontWeight.bold,
          shadows: shadows,
        ),
      );

      if (layer.isTextOutlineEnabled) {
        layerWidget = Stack(
          alignment: Alignment.center,
          children: [
            Text(
              layer.textContent,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: layer.fontSize,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = layer.textOutlineWidth
                  ..color = Color(layer.textOutlineColor),
              ),
            ),
            textMain,
          ],
        );
      } else {
        layerWidget = textMain;
      }
    } else if (layer.type == ClipType.sticker) {
      layerWidget = Text(
        layer.textContent,
        style: TextStyle(
          fontSize: layer.fontSize * 1.5,
          color: layer.color,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 10,
            ),
          ],
        ),
      );
    } else {
      final file = layer.assetPath != null ? File(layer.assetPath!) : null;
      if (file != null && file.existsSync()) {
        if (layer.type == ClipType.image) {
          layerWidget = Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _buildLayerPlaceholder(layer),
          );
        } else if (layer.type == ClipType.video) {
          final relMs =
              (playheadMs - layer.startMs).clamp(0, layer.durationMs);
          layerWidget = FutureBuilder<File?>(
            future: VideoThumbnailService()
                .getThumbnailFile(layer.assetPath!, atMs: relMs),
            builder: (context, snapshot) {
              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.existsSync()) {
                return Image.file(
                  snapshot.data!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => _buildLayerPlaceholder(layer),
                );
              }
              return _buildLayerPlaceholder(layer);
            },
          );
        } else {
          layerWidget = _buildLayerPlaceholder(layer);
        }
      } else {
        layerWidget = _buildLayerPlaceholder(layer);
      }
    }

    if (layer.isChromaKeyEnabled) {
      final chromaFilter = ColorFilterHelper.getChromaKeyFilter(
        layer.chromaKeyColor,
        layer.chromaThreshold,
        layer.chromaShowMask,
      );
      layerWidget =
          ColorFiltered(colorFilter: chromaFilter, child: layerWidget);
    } else if (filter != null) {
      layerWidget = ColorFiltered(colorFilter: filter, child: layerWidget);
    }

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

    final combinedScale = transform.scale * inScale * outScale * overallScale;
    final combinedRotation = transform.rotation + overallRotation;
    final combinedOpacity = (transform.opacity *
            inOpacity *
            outOpacity *
            overallOpacity)
        .clamp(0.0, 1.0);
    final combinedOffsetX = (transform.offsetX +
            inOffsetX +
            outOffsetX +
            overallOffsetX)
        .clamp(-2.0, 2.0);
    final combinedOffsetY = (transform.offsetY +
            inOffsetY +
            outOffsetY +
            overallOffsetY)
        .clamp(-2.0, 2.0);

    // Apply interpolated keyframe transform and positioning
    return Positioned.fill(
      child: Align(
        alignment: Alignment(combinedOffsetX, combinedOffsetY),
        child: Transform.rotate(
          angle: combinedRotation * (pi / 180),
          child: Transform.scale(
            scale: combinedScale,
            child: Opacity(
              opacity: combinedOpacity,
              child: layerWidget,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerPlaceholder(TimelineClip layer) {
    return Container(
      width: 140,
      height: 100,
      decoration: BoxDecoration(
        color: layer.color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        layer.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
