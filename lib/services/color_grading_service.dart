import 'dart:typed_data';
import 'rust_engine_service.dart';

class ColorGradingService {
  static final ColorGradingService instance = ColorGradingService._();
  ColorGradingService._();

  /// Processes raw RGBA pixel buffer using high-speed Rust SIMD grading
  Uint8List? processPixelsRgba(
    Uint8List pixels, {
    double brightness = 0.0,
    double contrast = 0.0,
    double saturation = 1.0,
    double temperature = 0.0,
    double tint = 0.0,
  }) {
    return RustEngineService.instance.colorGradeRgba(
      pixels,
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      temperature: temperature,
      tint: tint,
    );
  }

  /// Applies 3D LUT (Look-Up Table) to raw RGBA pixel buffer using native Rust
  Uint8List? applyLut3d(
    Uint8List pixels,
    Float32List lutTable,
    int lutSize, {
    double intensity = 1.0,
  }) {
    return RustEngineService.instance.applyLut3dRgba(
      pixels,
      lutTable,
      lutSize,
      intensity: intensity,
    );
  }

  /// Computes standard 5x4 ColorMatrix for Flutter real-time GPU preview
  List<double> calculateColorMatrix({
    double brightnessPercent = 0.0,
    double contrastPercent = 0.0,
    double saturationPercent = 0.0,
  }) {
    final b = (brightnessPercent / 100.0).clamp(-1.0, 1.0) * 255.0;
    final c = ((contrastPercent / 100.0).clamp(-1.0, 1.0) + 1.0).clamp(0.0, 3.0);
    final s = ((saturationPercent / 100.0) + 1.0).clamp(0.0, 3.0);

    final invSat = 1.0 - s;
    final r = 0.2126 * invSat;
    final g = 0.7152 * invSat;
    final bl = 0.0722 * invSat;

    return <double>[
      c * (r + s), c * g, c * bl, 0, b,
      c * r, c * (g + s), c * bl, 0, b,
      c * r, c * g, c * (bl + s), 0, b,
      0, 0, 0, 1, 0,
    ];
  }
}
