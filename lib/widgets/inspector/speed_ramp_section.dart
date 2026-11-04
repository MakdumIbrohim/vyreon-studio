import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

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

  void _applyPreset(SpeedRampPreset preset) {
    setState(() => _currentPreset = preset);
    final points = SpeedRampPreset.getPoints(preset);
    widget.controller.updateClip(widget.clip.copyWith(speedPoints: points));
  }

  void _updatePointSpeed(int index, double newSpeed) {
    final points = List<SpeedPoint>.from(widget.clip.speedPoints);
    if (index >= 0 && index < points.length) {
      points[index] = SpeedPoint(
        position: points[index].position,
        speed: newSpeed.clamp(0.2, 4.0),
      );
      setState(() => _currentPreset = SpeedRampPreset.custom);
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

          // Visual Curve Graph
          Container(
            height: 90,
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
                    painter: _SpeedCurvePainter(
                      points: points,
                      playheadProgress: relProgress,
                    ),
                  ),
                  // Draggable Point Handles
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;

                      return Stack(
                        children: [
                          for (int i = 0; i < points.length; i++)
                            Positioned(
                              left: (points[i].position * w) - 8,
                              top: ((1.0 - ((points[i].speed - 0.2) / 3.8)) * h)
                                      .clamp(0.0, h - 16) -
                                  0,
                              child: GestureDetector(
                                onVerticalDragUpdate: (details) {
                                  final dy = details.delta.dy;
                                  final deltaSpeed = -(dy / h) * 3.8;
                                  _updatePointSpeed(
                                      i, points[i].speed + deltaSpeed);
                                },
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Drag amber handles up/down to adjust speed (0.2x - 4.0x)',
              style: TextStyle(fontSize: 9, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedCurvePainter extends CustomPainter {
  final List<SpeedPoint> points;
  final double playheadProgress;

  _SpeedCurvePainter({
    required this.points,
    required this.playheadProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid baseline at 1.0x speed
    final baselineY = (1.0 - ((1.0 - 0.2) / 3.8)) * h;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, baselineY), Offset(w, baselineY), gridPaint);

    if (points.isEmpty) return;

    final sorted = List<SpeedPoint>.from(points)
      ..sort((a, b) => a.position.compareTo(b.position));

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < sorted.length; i++) {
      final x = sorted[i].position * w;
      final y = (1.0 - ((sorted[i].speed - 0.2) / 3.8)) * h;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(w, h);
    fillPath.close();

    // Fill under curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.cyanAccent.withValues(alpha: 0.3),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Line curve
    final linePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Playhead indicator vertical line
    final playheadX = playheadProgress * w;
    final playheadPaint = Paint()
      ..color = AppTheme.playhead
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(playheadX, 0), Offset(playheadX, h), playheadPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeedCurvePainter oldDelegate) => true;
}
