enum PipPreset {
  none('Custom / Off', 1.0, 0.0, 0.0),
  splitLeft('Split Left Half', 0.5, -0.5, 0.0),
  splitRight('Split Right Half', 0.5, 0.5, 0.0),
  splitTop('Split Top Half', 0.5, 0.0, -0.5),
  splitBottom('Split Bottom Half', 0.5, 0.0, 0.5),
  cornerTopRight('Corner Top-Right', 0.35, 0.6, -0.6),
  cornerTopLeft('Corner Top-Left', 0.35, -0.6, -0.6),
  cornerBottomRight('Corner Bottom-Right', 0.35, 0.6, 0.6),
  cornerBottomLeft('Corner Bottom-Left', 0.35, -0.6, 0.6),
  centerPip('Floating Center', 0.45, 0.0, 0.0);

  final String label;
  final double defaultScale;
  final double defaultOffsetX;
  final double defaultOffsetY;

  const PipPreset(this.label, this.defaultScale, this.defaultOffsetX, this.defaultOffsetY);
}
