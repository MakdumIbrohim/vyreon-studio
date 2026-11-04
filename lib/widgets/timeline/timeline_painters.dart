import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PlayheadPointerPainter extends CustomPainter {
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

class AudioWaveformPainter extends CustomPainter {
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
