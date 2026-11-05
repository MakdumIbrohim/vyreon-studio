import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/timeline_clip.dart';
import '../services/video_thumbnail_service.dart';
import '../state/editor_controller.dart';
import '../theme/app_theme.dart';
import '../utils/color_filters.dart';
import 'preview/direct_manipulation_overlay.dart';
import 'preview/eyedropper_overlay.dart';
import 'preview/layer_animation_evaluator.dart';
import 'preview/layer_content_builder.dart';
import 'preview/preview_placeholders.dart';
import 'preview/transition_renderer.dart';

class PreviewPlayer extends StatefulWidget {
  final EditorController controller;

  const PreviewPlayer({super.key, required this.controller});

  @override
  State<PreviewPlayer> createState() => _PreviewPlayerState();
}

class _PreviewPlayerState extends State<PreviewPlayer> {
  final GlobalKey _previewRepaintKey = GlobalKey();

  EditorController get controller => widget.controller;

  String _formatTimecode(int ms) {
    final totalSeconds = ms / 1000;
    final minutes = (totalSeconds / 60).floor();
    final seconds = (totalSeconds % 60).floor();
    final millis = ((ms % 1000) / 100).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
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
                child: RepaintBoundary(
                  key: _previewRepaintKey,
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
                                color:
                                    AppTheme.textMuted.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No Media at Current Time',
                                style: TextStyle(
                                  color: AppTheme.textMuted
                                      .withValues(alpha: 0.6),
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

                      // Subtitle Overlay (Bottom Centered)
                      for (final sub in project.subtitles)
                        if (playhead >= sub.startMs && playhead < sub.endMs)
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 24,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  sub.text,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                          blurRadius: 2, color: Colors.black),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),

            // Eyedropper Color Picker Loupe Overlay
            if (controller.isEyedropperActive)
              Positioned.fill(
                child: EyedropperOverlay(
                  controller: controller,
                  repaintBoundaryKey: _previewRepaintKey,
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
          errorBuilder: (_, _, _) =>
              PreviewPlaceholders.buildPlaceholderVisual(clip),
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
                    errorBuilder: (_, _, _) =>
                        PreviewPlaceholders.buildVideoPlaceholder(clip),
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
            return PreviewPlaceholders.buildVideoPlaceholder(clip);
          },
        );
      }
    } else {
      content = PreviewPlaceholders.buildPlaceholderVisual(clip);
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

    if (clip.cropMask.isMaskEnabled ||
        clip.cropMask.cropLeft > 0 ||
        clip.cropMask.cropTop > 0 ||
        clip.cropMask.cropRight > 0 ||
        clip.cropMask.cropBottom > 0) {
      content = ClipPath(
        clipper: ShapeMaskClipper(clip.cropMask),
        child: content,
      );
    }

    return Opacity(
      opacity: clip.opacity.clamp(0.0, 1.0),
      child: content,
    );
  }

  Widget _buildLayerVisual(TimelineClip layer, int playheadMs) {
    final filter = ColorFilterHelper.getPresetFilter(layer.filter);
    final baseTransform = layer.getInterpolatedTransform(playheadMs);

    // Build raw layer content (Text, Sticker, Image, Video)
    Widget layerWidget = LayerContentBuilder.build(
      layer: layer,
      playheadMs: playheadMs,
    );

    // Chroma Key
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

    // Crop & Shape Mask
    if (layer.cropMask.isMaskEnabled ||
        layer.cropMask.cropLeft > 0 ||
        layer.cropMask.cropTop > 0 ||
        layer.cropMask.cropRight > 0 ||
        layer.cropMask.cropBottom > 0) {
      layerWidget = ClipPath(
        clipper: ShapeMaskClipper(layer.cropMask),
        child: layerWidget,
      );
    }

    // Composite In/Out/Overall Animation & Keyframe transforms
    final evaluated = LayerAnimationEvaluator.evaluate(
      layer: layer,
      playheadMs: playheadMs,
      baseTransform: baseTransform,
    );

    return Positioned.fill(
      child: Align(
        alignment: Alignment(evaluated.offsetX, evaluated.offsetY),
        child: Transform.rotate(
          angle: evaluated.rotation * (pi / 180),
          child: Transform.scale(
            scale: evaluated.scale,
            child: Opacity(
              opacity: evaluated.opacity,
              child: layerWidget,
            ),
          ),
        ),
      ),
    );
  }
}
