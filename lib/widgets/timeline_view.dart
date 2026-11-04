import 'dart:math';
import 'package:flutter/material.dart';
import '../models/timeline_clip.dart';
import '../state/editor_controller.dart';
import '../theme/app_theme.dart';
import 'time_ruler.dart';

class TimelineView extends StatefulWidget {
  final EditorController controller;

  const TimelineView({super.key, required this.controller});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final ScrollController _scrollController = ScrollController();
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    if (widget.controller.isPlaying && !_isUserScrolling) {
      // Auto-scroll timeline to follow playhead
      final scale = widget.controller.timelineScale;
      final playheadPx = (widget.controller.playheadMs / 1000.0) * scale;
      final viewWidth = _scrollController.position.hasContentDimensions
          ? _scrollController.position.viewportDimension
          : 400.0;
      final targetScroll = playheadPx - (viewWidth / 2);

      if (_scrollController.hasClients) {
        final clamped = targetScroll.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(clamped);
      }
    }
  }

  double _msToPx(int ms, double scale) => (ms / 1000.0) * scale;
  int _pxToMs(double px, double scale) => ((px / scale) * 1000).round();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final project = controller.project;
        final scale = controller.timelineScale;
        final totalMs = max(5000, project.totalDurationMs + 5000);
        final totalWidth = max(800.0, _msToPx(totalMs, scale));

        final primaryClips = project.primaryClips;
        final secondaryClips = project.secondaryClips;

        final videoLayers = secondaryClips
            .where((c) =>
                c.type == ClipType.video ||
                c.type == ClipType.image ||
                c.type == ClipType.color ||
                c.type == ClipType.sticker)
            .toList();

        final textLayers =
            secondaryClips.where((c) => c.type == ClipType.text).toList();

        final audioLayers =
            secondaryClips.where((c) => c.type == ClipType.audio).toList();

        final playheadX = _msToPx(controller.playheadMs, scale);

        return Container(
          color: AppTheme.timelineBackground,
          child: Column(
            children: [
              // Zoom & Timecode Toolbar
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: AppTheme.surface,
                child: Row(
                  children: [
                    const Icon(Icons.timeline,
                        size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    const Text(
                      'TIMELINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    // Zoom Out
                    InkWell(
                      onTap: () =>
                          controller.setTimelineScale(scale - 15.0),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.zoom_out,
                            size: 18, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Zoom Slider
                    SizedBox(
                      width: 90,
                      child: Slider(
                        value: scale,
                        min: 20.0,
                        max: 180.0,
                        onChanged: (val) => controller.setTimelineScale(val),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Zoom In
                    InkWell(
                      onTap: () =>
                          controller.setTimelineScale(scale + 15.0),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.zoom_in,
                            size: 18, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppTheme.divider),

              // Scrollable Timeline Canvas
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notif) {
                    if (notif is ScrollStartNotification) {
                      _isUserScrolling = true;
                    } else if (notif is ScrollEndNotification) {
                      _isUserScrolling = false;
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final localX = details.localPosition.dx;
                        final targetMs = _pxToMs(localX, scale);
                        controller.seekTo(targetMs);
                        controller.selectClip(null);
                      },
                      child: SizedBox(
                        width: totalWidth,
                        child: Stack(
                          children: [
                            // Tracks Content
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Time Ruler (Top)
                                TimeRuler(
                                  scale: scale,
                                  totalDurationMs: totalMs,
                                  width: totalWidth,
                                ),

                                const Divider(
                                    height: 1, color: AppTheme.divider),

                                // Track 0: Primary Video Track
                                _buildPrimaryTrack(
                                  clips: primaryClips,
                                  scale: scale,
                                  totalWidth: totalWidth,
                                ),

                                const Divider(
                                    height: 1, color: AppTheme.divider),

                                // Track 1: Layers Track
                                _buildSecondaryTrack(
                                  clips: videoLayers,
                                  scale: scale,
                                  totalWidth: totalWidth,
                                  trackLabel: 'LAYERS',
                                  trackHeight: 38,
                                  color: AppTheme.timelineSecondaryClip,
                                ),

                                const Divider(
                                    height: 1, color: AppTheme.divider),

                                // Track 2: Text Track
                                _buildSecondaryTrack(
                                  clips: textLayers,
                                  scale: scale,
                                  totalWidth: totalWidth,
                                  trackLabel: 'TEXT',
                                  trackHeight: 34,
                                  color: AppTheme.timelineTextClip,
                                ),

                                const Divider(
                                    height: 1, color: AppTheme.divider),

                                // Track 3: Audio Track
                                _buildAudioTrack(
                                  clips: audioLayers,
                                  scale: scale,
                                  totalWidth: totalWidth,
                                ),
                              ],
                            ),

                            // Red Playhead Line
                            Positioned(
                              left: playheadX - 1,
                              top: 0,
                              bottom: 0,
                              child: IgnorePointer(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Vertical Line
                                    Container(
                                      width: 2,
                                      color: AppTheme.playhead,
                                    ),
                                    // Pointer Head
                                    Positioned(
                                      top: 0,
                                      left: -5,
                                      child: CustomPaint(
                                        size: const Size(12, 10),
                                        painter: _PlayheadPointerPainter(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrimaryTrack({
    required List<TimelineClip> clips,
    required double scale,
    required double totalWidth,
  }) {
    return Container(
      height: 58,
      width: totalWidth,
      color: AppTheme.timelineTrack,
      child: Stack(
        children: [
          // Background subtle track label
          Positioned(
            left: 8,
            top: 2,
            child: Text(
              'PRIMARY MEDIA TRACK',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted.withValues(alpha: 0.3),
              ),
            ),
          ),
          // Primary Clips
          for (int i = 0; i < clips.length; i++) ...[
            _buildClipWidget(
              clip: clips[i],
              scale: scale,
              height: 52,
            ),
            // Transition indicator between primary clips
            if (i < clips.length - 1)
              Positioned(
                left: _msToPx(clips[i].endMs, scale) - 8,
                top: 18,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.change_circle,
                    size: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecondaryTrack({
    required List<TimelineClip> clips,
    required double scale,
    required double totalWidth,
    required String trackLabel,
    required double trackHeight,
    required Color color,
  }) {
    return Container(
      height: trackHeight,
      width: totalWidth,
      color: AppTheme.timelineTrack.withValues(alpha: 0.8),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 2,
            child: Text(
              trackLabel,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted.withValues(alpha: 0.25),
              ),
            ),
          ),
          for (final clip in clips)
            _buildClipWidget(
              clip: clip,
              scale: scale,
              height: trackHeight - 6,
            ),
        ],
      ),
    );
  }

  Widget _buildAudioTrack({
    required List<TimelineClip> clips,
    required double scale,
    required double totalWidth,
  }) {
    return Container(
      height: 38,
      width: totalWidth,
      color: AppTheme.timelineTrack.withValues(alpha: 0.6),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 2,
            child: Text(
              'AUDIO TRACK',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted.withValues(alpha: 0.25),
              ),
            ),
          ),
          for (final clip in clips)
            _buildClipWidget(
              clip: clip,
              scale: scale,
              height: 32,
              isAudio: true,
            ),
        ],
      ),
    );
  }

  Widget _buildClipWidget({
    required TimelineClip clip,
    required double scale,
    required double height,
    bool isAudio = false,
  }) {
    final controller = widget.controller;
    final isSelected = controller.selectedClipId == clip.id;
    final left = _msToPx(clip.startMs, scale);
    final width = max(24.0, _msToPx(clip.durationMs, scale));

    return Positioned(
      left: left,
      top: 3,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => controller.selectClip(clip.id),
        child: Container(
          decoration: BoxDecoration(
            color: isAudio
                ? AppTheme.timelineAudioClip
                : (clip.isPrimary
                    ? AppTheme.timelinePrimaryClip
                    : (clip.type == ClipType.text
                        ? AppTheme.timelineTextClip
                        : AppTheme.timelineSecondaryClip)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD700) // Golden KineMaster yellow
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
              // Waveform pattern for audio
              if (isAudio)
                CustomPaint(
                  painter: _AudioWaveformPainter(),
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

              // Trim Handles when selected
              if (isSelected) ...[
                // Left Handle
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.drag_indicator,
                          size: 9, color: Colors.black87),
                    ),
                  ),
                ),
                // Right Handle
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.drag_indicator,
                          size: 9, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayheadPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.playhead;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AudioWaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.5;

    final step = 4.0;
    for (double x = 4; x < size.width - 4; x += step) {
      final h = sin(x * 0.1).abs() * (size.height * 0.6) + 4;
      final y1 = (size.height - h) / 2;
      canvas.drawLine(Offset(x, y1), Offset(x, y1 + h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
