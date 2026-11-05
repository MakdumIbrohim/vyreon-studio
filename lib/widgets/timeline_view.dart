import 'dart:math';
import 'package:flutter/material.dart';
import '../models/timeline_clip.dart';
import '../state/editor_controller.dart';
import '../theme/app_theme.dart';
import 'time_ruler.dart';
import 'timeline/timeline_playhead_widget.dart';
import 'timeline/timeline_zoom_toolbar.dart';
import 'timeline/tracks/audio_track_view.dart';
import 'timeline/tracks/primary_track_view.dart';
import 'timeline/tracks/secondary_track_view.dart';
import 'timeline/transition_selector_dialog.dart';

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

  Future<void> _editTransition(TimelineClip nextClip) async {
    final updated = await showDialog<TimelineClip>(
      context: context,
      builder: (ctx) => TransitionSelectorDialog(clip: nextClip),
    );

    if (updated != null) {
      widget.controller.updateClip(updated);
    }
  }

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
              TimelineZoomToolbar(controller: controller, scale: scale),

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
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          physics: const BouncingScrollPhysics(),
                          child: Stack(
                            children: [
                              // Tracks Content
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Time Ruler (Top)
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (details) {
                                      final targetMs = _pxToMs(
                                        details.localPosition.dx,
                                        scale,
                                      ).clamp(0, totalMs);
                                      controller.seekTo(targetMs, snapToBeat: true);
                                      controller.selectClip(null);
                                    },
                                    onHorizontalDragStart: (_) {
                                      if (controller.isPlaying) controller.pause();
                                    },
                                    onHorizontalDragUpdate: (details) {
                                      final targetMs = _pxToMs(
                                        details.localPosition.dx,
                                        scale,
                                      ).clamp(0, totalMs);
                                      controller.seekTo(targetMs, snapToBeat: true);
                                    },
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: TimeRuler(
                                        scale: scale,
                                        totalDurationMs: totalMs,
                                        width: totalWidth,
                                      ),
                                    ),
                                  ),

                                  const Divider(
                                      height: 1, color: AppTheme.divider),

                                  // Track 0: Primary Video Track
                                  PrimaryTrackView(
                                    clips: primaryClips,
                                    scale: scale,
                                    totalWidth: totalWidth,
                                    controller: controller,
                                    onEditTransition: _editTransition,
                                  ),

                                  const Divider(
                                      height: 1, color: AppTheme.divider),

                                  // Track 1: Layers Track
                                  if (videoLayers.isNotEmpty) ...[
                                    const Divider(
                                        height: 1, color: AppTheme.divider),
                                    SecondaryTrackView(
                                      clips: videoLayers,
                                      scale: scale,
                                      totalWidth: totalWidth,
                                      trackLabel: 'LAYERS',
                                      trackHeight: 38,
                                      controller: controller,
                                    ),
                                  ],

                                  // Track 2: Text Track
                                  if (textLayers.isNotEmpty) ...[
                                    const Divider(
                                        height: 1, color: AppTheme.divider),
                                    SecondaryTrackView(
                                      clips: textLayers,
                                      scale: scale,
                                      totalWidth: totalWidth,
                                      trackLabel: 'TEXT',
                                      trackHeight: 34,
                                      controller: controller,
                                    ),
                                  ],

                                  // Track 3: Audio Track
                                  if (audioLayers.isNotEmpty) ...[
                                    const Divider(
                                        height: 1, color: AppTheme.divider),
                                    AudioTrackView(
                                      clips: audioLayers,
                                      scale: scale,
                                      totalWidth: totalWidth,
                                      controller: controller,
                                    ),
                                  ],
                                ],
                              ),

                              // Interactive Red Playhead Line & Scrub Handle
                              TimelinePlayheadWidget(
                                controller: controller,
                                playheadX: playheadX,
                                scale: scale,
                                totalMs: totalMs,
                              ),
                            ],
                          ),
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
}
