import 'package:flutter/material.dart';

class ClipPatternPainter extends CustomPainter {
  final Color baseColor;
  ClipPatternPainter(this.baseColor);

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
