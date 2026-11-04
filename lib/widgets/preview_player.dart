import 'dart:math';
import 'package:flutter/material.dart';
import '../models/timeline_clip.dart';
import '../state/editor_controller.dart';
import '../theme/app_theme.dart';

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

  ColorFilter? _getFilter(ColorFilterPreset preset) {
    switch (preset) {
      case ColorFilterPreset.warm:
        return const ColorFilter.matrix(<double>[
          1.2, 0, 0, 0, 15,
          0, 1.0, 0, 0, 0,
          0, 0, 0.8, 0, -10,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.cool:
        return const ColorFilter.matrix(<double>[
          0.8, 0, 0, 0, -10,
          0, 1.0, 0, 0, 0,
          0, 0, 1.3, 0, 20,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.vivid:
        return const ColorFilter.matrix(<double>[
          1.3, -0.1, -0.1, 0, 0,
          -0.1, 1.3, -0.1, 0, 0,
          -0.1, -0.1, 1.3, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.mono:
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.vintage:
        return const ColorFilter.matrix(<double>[
          0.9, 0.5, 0.1, 0, 10,
          0.3, 0.8, 0.1, 0, 0,
          0.2, 0.3, 0.5, 0, -20,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.cyberpunk:
        return const ColorFilter.matrix(<double>[
          1.2, 0.0, 0.4, 0, 20,
          0.0, 0.8, 0.2, 0, -10,
          0.4, 0.0, 1.4, 0, 30,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.none:
        return null;
    }
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
                      // Primary Track Background
                      if (activePrimary != null)
                        _buildClipVisual(activePrimary)
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
                                  color: AppTheme.textMuted.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Secondary Overlay Layers
                      for (final layer in activeSecondaries)
                        _buildLayerVisual(layer),
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
    final filter = _getFilter(clip.filter);

    Widget content = Container(
      color: clip.color,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background subtle pattern
          CustomPaint(
            size: Size.infinite,
            painter: _ClipPatternPainter(clip.color),
          ),
          // Clip title badge
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

    if (filter != null) {
      content = ColorFiltered(colorFilter: filter, child: content);
    }

    return Opacity(
      opacity: clip.opacity.clamp(0.0, 1.0),
      child: content,
    );
  }

  Widget _buildLayerVisual(TimelineClip layer) {
    final filter = _getFilter(layer.filter);

    Widget layerWidget;
    if (layer.type == ClipType.text) {
      layerWidget = Text(
        layer.textContent,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: layer.color,
          fontSize: layer.fontSize,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
      );
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

    if (filter != null) {
      layerWidget = ColorFiltered(colorFilter: filter, child: layerWidget);
    }

    // Apply transform and positioning
    return Positioned.fill(
      child: Align(
        alignment: Alignment(layer.offsetX, layer.offsetY),
        child: Transform.rotate(
          angle: layer.rotation * (pi / 180),
          child: Transform.scale(
            scale: layer.scale,
            child: Opacity(
              opacity: layer.opacity.clamp(0.0, 1.0),
              child: layerWidget,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClipPatternPainter extends CustomPainter {
  final Color baseColor;
  _ClipPatternPainter(this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double i = -size.height; i < size.width; i += 32) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
