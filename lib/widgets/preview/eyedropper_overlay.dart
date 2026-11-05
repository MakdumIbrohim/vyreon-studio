import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class EyedropperOverlay extends StatefulWidget {
  final EditorController controller;
  final GlobalKey repaintBoundaryKey;

  const EyedropperOverlay({
    super.key,
    required this.controller,
    required this.repaintBoundaryKey,
  });

  @override
  State<EyedropperOverlay> createState() => _EyedropperOverlayState();
}

class _EyedropperOverlayState extends State<EyedropperOverlay> {
  Offset? _samplePosition;
  int _currentColor = 0xFF00FF00;

  @override
  void initState() {
    super.initState();
    _currentColor =
        widget.controller.eyedropperColor ?? widget.controller.selectedClip?.chromaKeyColor ?? 0xFF00FF00;
  }

  Future<void> _sampleColorAt(Offset localOffset, Size boundarySize) async {
    try {
      final boundary = widget.repaintBoundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;

      final x = localOffset.dx.clamp(0.0, boundarySize.width - 1).toInt();
      final y = localOffset.dy.clamp(0.0, boundarySize.height - 1).toInt();

      final width = image.width;
      final offset = (y * width + x) * 4;

      if (offset + 3 < byteData.lengthInBytes) {
        final r = byteData.getUint8(offset);
        final g = byteData.getUint8(offset + 1);
        final b = byteData.getUint8(offset + 2);
        // Alpha forced to 0xFF for pure opaque key color
        final sampled = (0xFF << 24) | (r << 16) | (g << 8) | b;

        setState(() {
          _samplePosition = localOffset;
          _currentColor = sampled;
        });
        widget.controller.eyedropperColor = sampled;
      }
    } catch (_) {}
  }

  String _toHex(int color) {
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            // Gesture Detector to drag/touch and sample pixels
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (details) =>
                    _sampleColorAt(details.localPosition, size),
                onPanUpdate: (details) =>
                    _sampleColorAt(details.localPosition, size),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            // Top Control Bar
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 6),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(Icons.close,
                          size: 18, color: Colors.white70),
                      onPressed: widget.controller.cancelEyedropper,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Color(_currentColor),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _toHex(_currentColor),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Drag or tap on preview to sample color',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: widget.controller.applyEyedropperColor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Apply Color',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),

            // Loupe & Reticle Pointer at sampled position
            if (_samplePosition != null)
              Positioned(
                left: _samplePosition!.dx - 30,
                top: _samplePosition!.dy - 70,
                child: IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(_currentColor),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      CustomPaint(
                        size: const Size(12, 8),
                        painter: _LoupePointerTrianglePainter(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LoupePointerTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
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
