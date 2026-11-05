import 'dart:math';
import 'package:flutter/material.dart';

enum MaskShape {
  rectangle('Rectangle'),
  circle('Circle'),
  roundedRect('Rounded'),
  triangle('Triangle'),
  star('Star'),
  heart('Heart');

  final String label;
  const MaskShape(this.label);
}

class ClipCropMask {
  final bool isMaskEnabled;
  final MaskShape maskShape;
  final double feather; // 0.0 to 1.0 (edge softness)
  final double cropLeft; // 0.0 to 0.45
  final double cropTop;
  final double cropRight;
  final double cropBottom;

  const ClipCropMask({
    this.isMaskEnabled = false,
    this.maskShape = MaskShape.rectangle,
    this.feather = 0.0,
    this.cropLeft = 0.0,
    this.cropTop = 0.0,
    this.cropRight = 0.0,
    this.cropBottom = 0.0,
  });

  ClipCropMask copyWith({
    bool? isMaskEnabled,
    MaskShape? maskShape,
    double? feather,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
  }) {
    return ClipCropMask(
      isMaskEnabled: isMaskEnabled ?? this.isMaskEnabled,
      maskShape: maskShape ?? this.maskShape,
      feather: feather ?? this.feather,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
    );
  }

  Map<String, dynamic> toJson() => {
    'isMaskEnabled': isMaskEnabled,
    'maskShape': maskShape.name,
    'feather': feather,
    'cropLeft': cropLeft,
    'cropTop': cropTop,
    'cropRight': cropRight,
    'cropBottom': cropBottom,
  };

  factory ClipCropMask.fromJson(Map<String, dynamic> json) {
    return ClipCropMask(
      isMaskEnabled: json['isMaskEnabled'] as bool? ?? false,
      maskShape: MaskShape.values.firstWhere(
        (e) => e.name == json['maskShape'],
        orElse: () => MaskShape.rectangle,
      ),
      feather: (json['feather'] as num?)?.toDouble() ?? 0.0,
      cropLeft: (json['cropLeft'] as num?)?.toDouble() ?? 0.0,
      cropTop: (json['cropTop'] as num?)?.toDouble() ?? 0.0,
      cropRight: (json['cropRight'] as num?)?.toDouble() ?? 0.0,
      cropBottom: (json['cropBottom'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Calculates clipping path for given bounding size
  Path getClipPath(Size size) {
    final left = size.width * cropLeft.clamp(0.0, 0.45);
    final top = size.height * cropTop.clamp(0.0, 0.45);
    final right = size.width * (1.0 - cropRight.clamp(0.0, 0.45));
    final bottom = size.height * (1.0 - cropBottom.clamp(0.0, 0.45));

    final rect = Rect.fromLTRB(left, top, right, bottom);
    final path = Path();

    if (!isMaskEnabled || maskShape == MaskShape.rectangle) {
      path.addRect(rect);
      return path;
    }

    switch (maskShape) {
      case MaskShape.circle:
        path.addOval(rect);
        break;
      case MaskShape.roundedRect:
        final radius = Radius.circular(min(rect.width, rect.height) * 0.2);
        path.addRRect(RRect.fromRectAndRadius(rect, radius));
        break;
      case MaskShape.triangle:
        path.moveTo(rect.center.dx, rect.top);
        path.lineTo(rect.right, rect.bottom);
        path.lineTo(rect.left, rect.bottom);
        path.close();
        break;
      case MaskShape.star:
        _addStarPath(path, rect);
        break;
      case MaskShape.heart:
        _addHeartPath(path, rect);
        break;
      case MaskShape.rectangle:
        path.addRect(rect);
        break;
    }
    return path;
  }

  void _addStarPath(Path path, Rect rect) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final outerR = min(rect.width, rect.height) / 2;
    final innerR = outerR * 0.45;
    const points = 5;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - (pi / 2);
      final r = i.isEven ? outerR : innerR;
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
  }

  void _addHeartPath(Path path, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    final l = rect.left;
    final t = rect.top;

    path.moveTo(l + w / 2, t + h / 4);
    path.cubicTo(l + w / 2, t, l, t, l, t + h / 3);
    path.cubicTo(l, t + h * 0.6, l + w / 2, t + h * 0.85, l + w / 2, t + h);
    path.cubicTo(l + w / 2, t + h * 0.85, l + w, t + h * 0.6, l + w, t + h / 3);
    path.cubicTo(l + w, t, l + w / 2, t, l + w / 2, t + h / 4);
    path.close();
  }
}

class ShapeMaskClipper extends CustomClipper<Path> {
  final ClipCropMask cropMask;
  ShapeMaskClipper(this.cropMask);

  @override
  Path getClip(Size size) => cropMask.getClipPath(size);

  @override
  bool shouldReclip(covariant ShapeMaskClipper oldClipper) {
    return oldClipper.cropMask.isMaskEnabled != cropMask.isMaskEnabled ||
        oldClipper.cropMask.maskShape != cropMask.maskShape ||
        oldClipper.cropMask.cropLeft != cropMask.cropLeft ||
        oldClipper.cropMask.cropTop != cropMask.cropTop ||
        oldClipper.cropMask.cropRight != cropMask.cropRight ||
        oldClipper.cropMask.cropBottom != cropMask.cropBottom;
  }
}
