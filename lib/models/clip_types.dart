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
  warm('Warm Sunset'),
  cool('Cool Slate'),
  vivid('Vivid Pop'),
  mono('Monochrome'),
  vintage('Vintage 90s'),
  cyberpunk('Cyberpunk Neon'),
  tealAndOrange('Teal & Orange'),
  filmNoir('Film Noir'),
  sepia('Warm Sepia'),
  bleachBypass('Bleach Bypass'),
  emerald('Emerald Forest');

  final String label;
  const ColorFilterPreset(this.label);
}
