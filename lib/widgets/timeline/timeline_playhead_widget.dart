import 'package:flutter/material.dart';
import '../../state/editor_controller.dart';
import 'timeline_painters.dart';

class TimelinePlayheadWidget extends StatefulWidget {
  final EditorController controller;
  final double playheadX;
  final double scale;
  final int totalMs;

  const TimelinePlayheadWidget({
    super.key,
    required this.controller,
    required this.playheadX,
    required this.scale,
    required this.totalMs,
  });

  @override
  State<TimelinePlayheadWidget> createState() => _TimelinePlayheadWidgetState();
}

class _TimelinePlayheadWidgetState extends State<TimelinePlayheadWidget> {
  double _dragStartGlobalX = 0;
  int _dragStartPlayheadMs = 0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.playheadX - 18,
      top: 0,
      width: 36,
      height: 28,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            if (widget.controller.isPlaying) {
              widget.controller.pause();
            }
            _dragStartGlobalX = details.globalPosition.dx;
            _dragStartPlayheadMs = widget.controller.playheadMs;
          },
          onHorizontalDragUpdate: (details) {
            if (widget.scale <= 0) return;
            final deltaPx = details.globalPosition.dx - _dragStartGlobalX;
            final deltaMs = ((deltaPx / widget.scale) * 1000).round();
            final targetMs =
                (_dragStartPlayheadMs + deltaMs).clamp(0, widget.totalMs);
            widget.controller.seekTo(targetMs, snapToBeat: true);
          },
          child: Align(
            alignment: Alignment.topCenter,
            child: CustomPaint(
              size: const Size(12, 10),
              painter: PlayheadPointerPainter(),
            ),
          ),
        ),
      ),
    );
  }
}
