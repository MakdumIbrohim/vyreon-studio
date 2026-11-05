import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/timeline_clip.dart';
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
        content = Container(
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
    } else {
      content = _buildPlaceholderVisual(clip);
    }

    if (filter != null) {
      content = ColorFiltered(colorFilter: filter, child: content);
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
      layerWidget = Container(
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

    // Apply interpolated keyframe transform and positioning
    return Positioned.fill(
      child: Align(
        alignment: Alignment(transform.offsetX, transform.offsetY),
        child: Transform.rotate(
          angle: transform.rotation * (pi / 180),
          child: Transform.scale(
            scale: transform.scale,
            child: Opacity(
              opacity: transform.opacity.clamp(0.0, 1.0),
              child: layerWidget,
            ),
          ),
        ),
      ),
    );
  }
}
