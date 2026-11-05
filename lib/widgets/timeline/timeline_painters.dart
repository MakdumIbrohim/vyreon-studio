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
  final List<double> samples;
  final double volume;
  final bool isMuted;
  final double playheadProgress;

  const AudioWaveformPainter({
    this.samples = const [],
    this.volume = 1.0,
    this.isMuted = false,
    this.playheadProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final centerY = size.height / 2;
    final maxHalfHeight = (size.height / 2) - 4;

    // If muted, draw a quiet center flatline
    if (isMuted || volume <= 0.01) {
      final flatPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(4, centerY),
        Offset(size.width - 4, centerY),
        flatPaint,
      );
      return;
    }

    final barWidth = 2.0;
    final gap = 1.5;
    final step = barWidth + gap;
    final totalBars = ((size.width - 8) / step).floor();
    if (totalBars <= 0) return;

    final playedBoundaryX = size.width * playheadProgress.clamp(0.0, 1.0);

    final playedPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.85) // bright green
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    final unplayedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < totalBars; i++) {
      final x = 4.0 + (i * step);

      // Determine sample amplitude
      double amp = 0.3;
      if (samples.isNotEmpty) {
        final sampleIdx = ((i / totalBars) * samples.length).floor().clamp(0, samples.length - 1);
        amp = samples[sampleIdx];
      } else {
        // Fallback rhythmic sine-cosine wave
        amp = (sin(i * 0.25).abs() * 0.7 + cos(i * 0.1).abs() * 0.3).clamp(0.1, 0.95);
      }

      // Scale by clip volume
      final h = (amp * maxHalfHeight * volume.clamp(0.0, 1.5)).clamp(2.0, maxHalfHeight);

      final paint = x <= playedBoundaryX ? playedPaint : unplayedPaint;
      canvas.drawLine(
        Offset(x, centerY - h),
        Offset(x, centerY + h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.volume != volume ||
        oldDelegate.isMuted != isMuted ||
        oldDelegate.playheadProgress != playheadProgress;
  }
}
