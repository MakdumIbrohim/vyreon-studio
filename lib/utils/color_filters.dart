import 'package:flutter/material.dart';
import '../models/clip_types.dart';

class ColorFilterHelper {
  static ColorFilter? getPresetFilter(ColorFilterPreset preset) {
    switch (preset) {
      case ColorFilterPreset.warm:
        return const ColorFilter.matrix(<double>[
          1.2, 0, 0, 0, 15,
          0, 1.0, 0, 0, 0,
          0, 0, 0.8, 0, -10,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.cool:
        return const ColorFilter.matrix(<double>[
          0.8, 0, 0, 0, -10,
          0, 1.0, 0, 0, 0,
          0, 0, 1.3, 0, 20,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.vivid:
        return const ColorFilter.matrix(<double>[
          1.3, -0.1, -0.1, 0, 0,
          -0.1, 1.3, -0.1, 0, 0,
          -0.1, -0.1, 1.3, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.mono:
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.vintage:
        return const ColorFilter.matrix(<double>[
          0.9, 0.5, 0.1, 0, 10,
          0.3, 0.8, 0.1, 0, 0,
          0.2, 0.3, 0.5, 0, -20,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.cyberpunk:
        return const ColorFilter.matrix(<double>[
          1.2, 0.0, 0.4, 0, 20,
          0.0, 0.8, 0.2, 0, -10,
          0.4, 0.0, 1.4, 0, 30,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.tealAndOrange:
        return const ColorFilter.matrix(<double>[
          1.35, 0.0, -0.1, 0, 15,
          0.0, 1.05, 0.05, 0, -5,
          -0.2, 0.2, 1.4, 0, 25,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.filmNoir:
        return const ColorFilter.matrix(<double>[
          0.5, 0.8, 0.1, 0, -20,
          0.5, 0.8, 0.1, 0, -20,
          0.5, 0.8, 0.1, 0, -20,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.sepia:
        return const ColorFilter.matrix(<double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.bleachBypass:
        return const ColorFilter.matrix(<double>[
          0.9, 0.2, 0.1, 0, -10,
          0.2, 0.9, 0.1, 0, -10,
          0.2, 0.2, 0.8, 0, -10,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.emerald:
        return const ColorFilter.matrix(<double>[
          0.85, 0.1, 0.0, 0, -10,
          0.1, 1.35, 0.1, 0, 15,
          0.0, 0.1, 0.9, 0, -5,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterPreset.none:
        return null;
    }
  }

  static ColorFilter getChromaKeyFilter(
    int keyColor,
    double threshold,
    bool showMask,
  ) {
    if (showMask) {
      return const ColorFilter.matrix(<double>[
        2.0, -2.0, 2.0, 0, 0,
        2.0, -2.0, 2.0, 0, 0,
        2.0, -2.0, 2.0, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    }

    final isGreen = ((keyColor >> 8) & 0xFF) > ((keyColor >> 16) & 0xFF) &&
        ((keyColor >> 8) & 0xFF) > (keyColor & 0xFF);

    if (isGreen) {
      return const ColorFilter.matrix(<double>[
        1.0, 0.0, 0.0, 0, 0,
        0.0, 0.15, 0.0, 0, 0,
        0.0, 0.0, 1.0, 0, 0,
        0.6, -1.2, 0.6, 1, 0,
      ]);
    } else {
      return const ColorFilter.matrix(<double>[
        1.0, 0.0, 0.0, 0, 0,
        0.0, 1.0, 0.0, 0, 0,
        0.0, 0.0, 0.15, 0, 0,
        0.6, 0.6, -1.2, 1, 0,
      ]);
    }
  }
}
