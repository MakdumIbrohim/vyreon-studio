import 'package:flutter/material.dart';

enum TransitionType {
  none('None / Cut', Icons.block),
  fade('Crossfade', Icons.blur_linear),
  wipeLeft('Wipe', Icons.swipe_left),
  slideUp('Slide Up', Icons.arrow_upward),
  zoom('Zoom Dissolve', Icons.zoom_in);

  final String label;
  final IconData icon;
  const TransitionType(this.label, this.icon);
}
