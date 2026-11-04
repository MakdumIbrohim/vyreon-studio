import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TimeRuler extends StatelessWidget {
  final double scale; // px per second
  final int totalDurationMs;
  final double width;

  const TimeRuler({
    super.key,
    required this.scale,
    required this.totalDurationMs,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      width: width,
      child: CustomPaint(
        size: Size(width, 24),
        painter: _TimeRulerPainter(
          scale: scale,
          totalDurationMs: totalDurationMs,
        ),
      ),
    );
  }
}

class _TimeRulerPainter extends CustomPainter {
  final double scale;
  final int totalDurationMs;

  _TimeRulerPainter({
    required this.scale,
    required this.totalDurationMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = AppTheme.textMuted.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: AppTheme.textMuted.withValues(alpha: 0.8),
      fontSize: 9,
      fontFamily: 'monospace',
    );

    // Decide interval based on scale:
    // If scale > 100, interval = 1s, minor = 0.2s
    // If scale > 40, interval = 2s, minor = 0.5s
    // else interval = 5s, minor = 1s
    final int majorStepSec = scale > 80 ? 1 : (scale > 35 ? 2 : 5);
    final int totalSec = (totalDurationMs / 1000).ceil() + 5;

    for (int sec = 0; sec <= totalSec; sec++) {
      final double x = sec * scale;
      if (x > size.width) break;

      if (sec % majorStepSec == 0) {
        // Major tick
        canvas.drawLine(Offset(x, 12), Offset(x, size.height), tickPaint);

        final m = sec ~/ 60;
        final s = sec % 60;
        final label =
            '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        final textSpan = TextSpan(text: label, style: textStyle);
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + 2, 0));
      } else {
        // Minor tick
        canvas.drawLine(Offset(x, 18), Offset(x, size.height), tickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimeRulerPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.totalDurationMs != totalDurationMs;
  }
}
