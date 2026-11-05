import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../theme/app_theme.dart';

class SpeedCurvePainter extends CustomPainter {
  final List<SpeedPoint> points;
  final double playheadProgress;
  final int? activeIndex;

  SpeedCurvePainter({
    required this.points,
    required this.playheadProgress,
    this.activeIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid baseline at 1.0x speed
    final baselineY = (1.0 - ((1.0 - 0.2) / 3.8)) * h;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, baselineY), Offset(w, baselineY), gridPaint);

    // 2.0x grid line
    final speed2Y = (1.0 - ((2.0 - 0.2) / 3.8)) * h;
    canvas.drawLine(
      Offset(0, speed2Y),
      Offset(w, speed2Y),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..strokeWidth = 1.0,
    );

    if (points.isEmpty) return;

    final sorted = List<SpeedPoint>.from(points)
      ..sort((a, b) => a.position.compareTo(b.position));

    final path = Path();
    final fillPath = Path();

    final offsets = <Offset>[];
    for (int i = 0; i < sorted.length; i++) {
      final x = sorted[i].position * w;
      final y = (1.0 - ((sorted[i].speed - 0.2) / 3.8)) * h;
      offsets.add(Offset(x, y));
    }

    // Build smooth cubic bezier curve
    path.moveTo(offsets.first.dx, offsets.first.dy);
    fillPath.moveTo(offsets.first.dx, h);
    fillPath.lineTo(offsets.first.dx, offsets.first.dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(w, h);
    fillPath.close();

    // Fill under curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.cyanAccent.withValues(alpha: 0.25),
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
    final playheadX = (playheadProgress * w).clamp(0.0, w);
    final playheadPaint = Paint()
      ..color = AppTheme.playhead
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(playheadX, 0), Offset(playheadX, h), playheadPaint);
  }

  @override
  bool shouldRepaint(covariant SpeedCurvePainter oldDelegate) => true;
}
