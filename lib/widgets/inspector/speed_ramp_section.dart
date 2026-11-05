import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';
import '../speed_ramp/speed_curve_painter.dart';

class SpeedRampSection extends StatefulWidget {
  final EditorController controller;
  final TimelineClip clip;

  const SpeedRampSection({
    super.key,
    required this.controller,
    required this.clip,
  });

  @override
  State<SpeedRampSection> createState() => _SpeedRampSectionState();
}

class _SpeedRampSectionState extends State<SpeedRampSection> {
  SpeedRampPreset _currentPreset = SpeedRampPreset.constant;
  int? _activeNodeIndex;

  void _applyPreset(SpeedRampPreset preset) {
    setState(() => _currentPreset = preset);
    final points = SpeedRampPreset.getPoints(preset);
    widget.controller.updateClip(widget.clip.copyWith(speedPoints: points));
  }

  void _updatePoint(int index, double newPosition, double newSpeed) {
    final points = List<SpeedPoint>.from(widget.clip.speedPoints);
    if (index >= 0 && index < points.length) {
      final isFirst = index == 0;
      final isLast = index == points.length - 1;

      final clampedPos = isFirst
          ? 0.0
          : isLast
              ? 1.0
              : newPosition.clamp(0.05, 0.95);

      points[index] = SpeedPoint(
        position: clampedPos,
        speed: newSpeed.clamp(0.2, 4.0),
      );
      points.sort((a, b) => a.position.compareTo(b.position));
      setState(() => _currentPreset = SpeedRampPreset.custom);
      widget.controller.updateClip(widget.clip.copyWith(speedPoints: points));
    }
  }

  void _addPoint(double position, double speed) {
    final points = List<SpeedPoint>.from(widget.clip.speedPoints);
    points.add(SpeedPoint(
      position: position.clamp(0.05, 0.95),
      speed: speed.clamp(0.2, 4.0),
    ));
    points.sort((a, b) => a.position.compareTo(b.position));
    setState(() => _currentPreset = SpeedRampPreset.custom);
    widget.controller.updateClip(widget.clip.copyWith(speedPoints: points));
  }

  void _deletePoint(int index) {
    final points = List<SpeedPoint>.from(widget.clip.speedPoints);
    if (points.length > 2 && index > 0 && index < points.length - 1) {
      points.removeAt(index);
      setState(() {
        _currentPreset = SpeedRampPreset.custom;
        _activeNodeIndex = null;
      });
      widget.controller.updateClip(widget.clip.copyWith(speedPoints: points));
    }
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final points = clip.speedPoints.isNotEmpty
        ? clip.speedPoints
        : SpeedRampPreset.getPoints(SpeedRampPreset.constant);

    final relProgress = clip.durationMs > 0
        ? ((widget.controller.playheadMs - clip.startMs) / clip.durationMs)
            .clamp(0.0, 1.0)
        : 0.0;
    final currentSpeed = clip.getEffectiveSpeedAt(relProgress);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Speed Ramping (Curve)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${currentSpeed.toStringAsFixed(2)}x at Playhead',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Preset Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SpeedRampPreset.values.map((preset) {
                final isSel = _currentPreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      preset.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surfaceVariant,
                    onSelected: (_) => _applyPreset(preset),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Interactive Visual Curve Canvas
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.timelineBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.divider.withValues(alpha: 0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: SpeedCurvePainter(
                      points: points,
                      playheadProgress: relProgress,
                      activeIndex: _activeNodeIndex,
                    ),
                  ),

                  // Tap to add speed point
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;

                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (details) {
                          final tapX = details.localPosition.dx / w;
                          final tapY = details.localPosition.dy / h;
                          final targetSpeed = (1.0 - tapY) * 3.8 + 0.2;
                          _addPoint(tapX, targetSpeed);
                        },
                        child: Stack(
                          children: [
                            for (int i = 0; i < points.length; i++)
                              Positioned(
                                left: (points[i].position * w) - 10,
                                top: ((1.0 - ((points[i].speed - 0.2) / 3.8)) *
                                        h)
                                    .clamp(0.0, h - 20),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onDoubleTap: () => _deletePoint(i),
                                  onPanStart: (_) =>
                                      setState(() => _activeNodeIndex = i),
                                  onPanEnd: (_) =>
                                      setState(() => _activeNodeIndex = null),
                                  onPanUpdate: (details) {
                                    final currentX = points[i].position * w;
                                    final currentY = (1.0 -
                                            ((points[i].speed - 0.2) / 3.8)) *
                                        h;

                                    final nextX = currentX + details.delta.dx;
                                    final nextY = currentY + details.delta.dy;

                                    final newPos = nextX / w;
                                    final newSpeed =
                                        (1.0 - (nextY / h)) * 3.8 + 0.2;
                                    _updatePoint(i, newPos, newSpeed);
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: _activeNodeIndex == i
                                          ? Colors.cyanAccent
                                          : Colors.amber,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_activeNodeIndex == i
                                                  ? Colors.cyanAccent
                                                  : Colors.black)
                                              .withValues(alpha: 0.6),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Drag handles (X/Y) • Tap curve to add node • Double-tap node to delete',
              style: TextStyle(fontSize: 9, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
