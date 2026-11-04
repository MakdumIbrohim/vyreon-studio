import 'package:flutter/material.dart';

enum ClipType {
  video(Icons.videocam, 'Video'),
  image(Icons.image, 'Image'),
  color(Icons.palette, 'Solid Color'),
  text(Icons.title, 'Text'),
  audio(Icons.audiotrack, 'Audio'),
  sticker(Icons.auto_awesome, 'Graphic');

  final IconData icon;
  final String label;
  const ClipType(this.icon, this.label);
}

enum ColorFilterPreset {
  none('Normal'),
  warm('Warm'),
  cool('Cool'),
  vivid('Vivid'),
  mono('Monochrome'),
  vintage('Vintage'),
  cyberpunk('Cyberpunk');

  final String label;
  const ColorFilterPreset(this.label);
}
