import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../services/video_thumbnail_service.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';
import 'timeline_painters.dart';

class TimelineClipWidget extends StatefulWidget {
  final TimelineClip clip;
  final double scale;
  final double height;
  final bool isAudio;
  final EditorController controller;

  const TimelineClipWidget({
    super.key,
    required this.clip,
    required this.scale,
    required this.height,
    this.isAudio = false,
    required this.controller,
  });

  @override
  State<TimelineClipWidget> createState() => _TimelineClipWidgetState();
}

class _TimelineClipWidgetState extends State<TimelineClipWidget> {
  double _dragStartGlobalX = 0;
  int _dragStartDurationMs = 0;
  int _dragStartStartMs = 0;

  double _msToPx(int ms, double scale) => (ms / 1000.0) * scale;
  int _pxToMs(double px, double scale) =>
      scale > 0 ? ((px / scale) * 1000).round() : 0;

  void _onLeftDragStart(DragStartDetails details) {
    if (widget.controller.isPlaying) {
      widget.controller.pause();
    }
    widget.controller.pushUndo();
    _dragStartGlobalX = details.globalPosition.dx;
    _dragStartStartMs = widget.clip.startMs;
    _dragStartDurationMs = widget.clip.durationMs;
  }

  void _onLeftDragUpdate(DragUpdateDetails details) {
    final deltaPx = details.globalPosition.dx - _dragStartGlobalX;
    final deltaMs = _pxToMs(deltaPx, widget.scale);

    if (widget.clip.isPrimary) {
      final newDuration = max(300, _dragStartDurationMs - deltaMs);
      widget.controller.updateClipLive(
        widget.clip.copyWith(
          durationMs: newDuration,
          sourceDurationMs: newDuration,
        ),
      );
    } else {
      final origEndMs = _dragStartStartMs + _dragStartDurationMs;
      final newStartMs =
          (_dragStartStartMs + deltaMs).clamp(0, origEndMs - 300);
      final newDuration = origEndMs - newStartMs;
      widget.controller.updateClipLive(
        widget.clip.copyWith(
          startMs: newStartMs,
          durationMs: newDuration,
          sourceDurationMs: newDuration,
        ),
      );
    }
  }

  void _onLeftDragEnd(DragEndDetails details) {
    widget.controller.autoSave();
  }

  void _onRightDragStart(DragStartDetails details) {
    if (widget.controller.isPlaying) {
      widget.controller.pause();
    }
    widget.controller.pushUndo();
    _dragStartGlobalX = details.globalPosition.dx;
    _dragStartDurationMs = widget.clip.durationMs;
  }

  void _onRightDragUpdate(DragUpdateDetails details) {
    final deltaPx = details.globalPosition.dx - _dragStartGlobalX;
    final deltaMs = _pxToMs(deltaPx, widget.scale);
    final newDuration = max(300, _dragStartDurationMs + deltaMs);

    widget.controller.updateClipLive(
      widget.clip.copyWith(
        durationMs: newDuration,
        sourceDurationMs: newDuration,
      ),
    );
  }

  void _onRightDragEnd(DragEndDetails details) {
    widget.controller.autoSave();
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final scale = widget.scale;
    final controller = widget.controller;
    final isSelected = controller.selectedClipId == clip.id;
    final left = _msToPx(clip.startMs, scale);
    final width = max(24.0, _msToPx(clip.durationMs, scale));

    return Positioned(
      left: left,
      top: 3,
      width: width,
      height: widget.height,
      child: GestureDetector(
        onTapUp: (details) {
          final currentPlayhead = controller.playheadMs;
          int targetMs;

          if (clip.endMs <= currentPlayhead) {
            // Clicked a layer to the left -> jump to left (clip.startMs)
            targetMs = clip.startMs;
          } else if (clip.startMs >= currentPlayhead) {
            // Clicked a layer to the right -> jump to right (clip.endMs)
            targetMs = clip.endMs;
          } else {
            // Clicked inside active clip: left half jumps to start, right half to end
            final isLeftHalf = details.localPosition.dx < (width / 2);
            targetMs = isLeftHalf ? clip.startMs : clip.endMs;
          }

          controller.selectClip(clip.id);
          controller.seekTo(targetMs, snapToBeat: false);
        },
        child: Container(
          decoration: BoxDecoration(
            color: widget.isAudio
                ? AppTheme.timelineAudioClip
                : (clip.isPrimary
                    ? AppTheme.timelinePrimaryClip
                    : (clip.type == ClipType.text
                        ? AppTheme.timelineTextClip
                        : AppTheme.timelineSecondaryClip)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD700)
                  : Colors.white.withValues(alpha: 0.15),
              width: isSelected ? 2.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media Thumbnail/Preview based on clip media type
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: _buildMediaBackground(clip),
              ),

              // Gradient Overlay for text readability
              if (clip.type != ClipType.audio && !widget.isAudio)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),

              // Waveform pattern for audio
              if (widget.isAudio || clip.type == ClipType.audio)
                CustomPaint(
                  painter: AudioWaveformPainter(
                    samples: clip.waveformSamples,
                    volume: clip.volume,
                    isMuted: clip.isMuted,
                    playheadProgress: clip.durationMs > 0
                        ? ((controller.playheadMs - clip.startMs) /
                                clip.durationMs)
                            .clamp(0.0, 1.0)
                        : 0.0,
                  ),
                ),

              // Keyframe Markers
              for (final k in clip.keyframes)
                Positioned(
                  left: (_msToPx(k.timeMs, scale) - 4).clamp(0.0, width - 8),
                  bottom: 3,
                  child: Transform.rotate(
                    angle: pi / 4,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        border: Border.all(color: Colors.black87, width: 0.8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Beat Markers (Amber Rhythmic Pin Dots)
              for (final beatMs in clip.beatMarkers)
                Positioned(
                  left: (_msToPx(beatMs, scale) - 3).clamp(0.0, width - 6),
                  top: 2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.amberAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 0.8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

              // Clip Content Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Icon(
                      clip.type.icon,
                      size: 13,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        clip.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (width > 60)
                      Text(
                        '${(clip.durationMs / 1000).toStringAsFixed(1)}s',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),

              // Trim & Stretch Handles:
              // Only active for static clips (image, color, text, sticker).
              // Video clips have fixed media duration and cannot be dragged to stretch/trim.
              if (isSelected && clip.isStatic) ...[
                _buildLeftHandle(width),
                _buildRightHandle(width),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftHandle(double clipWidth) {
    final handleWidth = clipWidth < 40 ? 8.0 : 14.0;

    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: handleWidth,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onLeftDragStart,
          onHorizontalDragUpdate: _onLeftDragUpdate,
          onHorizontalDragEnd: _onLeftDragEnd,
          child: Container(
            width: handleWidth,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.drag_indicator,
                size: 10,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightHandle(double clipWidth) {
    final handleWidth = clipWidth < 40 ? 8.0 : 14.0;

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: handleWidth,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onRightDragStart,
          onHorizontalDragUpdate: _onRightDragUpdate,
          onHorizontalDragEnd: _onRightDragEnd,
          child: Container(
            width: handleWidth,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.drag_indicator,
                size: 10,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaBackground(TimelineClip clip) {
    if (clip.type == ClipType.image && clip.assetPath != null) {
      final file = File(clip.assetPath!);
      if (file.existsSync()) {
        return Opacity(
          opacity: 0.6,
          child: Image.file(
            file,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        );
      }
    } else if (clip.type == ClipType.video && clip.assetPath != null) {
      final file = File(clip.assetPath!);
      if (file.existsSync()) {
        return Opacity(
          opacity: 0.6,
          child: FutureBuilder<File?>(
            future: VideoThumbnailService().getThumbnailFile(
              clip.assetPath!,
              atMs: clip.sourceInMs,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.existsSync()) {
                return Image.file(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      }
    } else if (clip.type == ClipType.color) {
      return Container(
        color: Color(clip.colorValue).withValues(alpha: 0.65),
      );
    }
    return const SizedBox.shrink();
  }
}
