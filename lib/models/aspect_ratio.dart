import 'package:flutter/material.dart';

enum ProjectAspectRatio {
  ratio16x9('16:9', 16, 9, 'YouTube, TV', Icons.crop_16_9),
  ratio9x16('9:16', 9, 16, 'TikTok, Reels, Shorts', Icons.crop_portrait),
  ratio1x1('1:1', 1, 1, 'Instagram Feed', Icons.crop_square),
  ratio4x3('4:3', 4, 3, 'Tablet, Standard TV', Icons.aspect_ratio),
  ratio3x4('3:4', 3, 4, 'Portrait Tablet', Icons.crop_7_5),
  ratio4x5('4:5', 4, 5, 'Instagram Portrait', Icons.crop_5_4),
  ratio235x1('2.35:1', 235, 100, 'Cinemascope', Icons.movie_outlined);

  final String label;
  final int widthRatio;
  final int heightRatio;
  final String description;
  final IconData icon;

  const ProjectAspectRatio(
    this.label,
    this.widthRatio,
    this.heightRatio,
    this.description,
    this.icon,
  );

  double get value => widthRatio / heightRatio;

  Size getTargetResolution({int targetLongEdge = 1920}) {
    if (widthRatio >= heightRatio) {
      final w = targetLongEdge;
      final h = (targetLongEdge * heightRatio / widthRatio).round();
      return Size(w.toDouble(), h.toDouble());
    } else {
      final h = targetLongEdge;
      final w = (targetLongEdge * widthRatio / heightRatio).round();
      return Size(w.toDouble(), h.toDouble());
    }
  }

  static ProjectAspectRatio fromString(String val) {
    for (final r in values) {
      if (r.label == val || r.name == val) return r;
    }
    return ratio16x9;
  }
}
