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
      // Silhouette mask: White for foreground, black for key
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
      // Chroma key Green: suppress green spill and attenuate alpha for green
      return const ColorFilter.matrix(<double>[
        1.0, 0.0, 0.0, 0, 0,
        0.0, 0.15, 0.0, 0, 0,
        0.0, 0.0, 1.0, 0, 0,
        0.6, -1.2, 0.6, 1, 0,
      ]);
    } else {
      // Chroma key Blue: suppress blue spill and attenuate alpha for blue
      return const ColorFilter.matrix(<double>[
        1.0, 0.0, 0.0, 0, 0,
        0.0, 1.0, 0.0, 0, 0,
        0.0, 0.0, 0.15, 0, 0,
        0.6, 0.6, -1.2, 1, 0,
      ]);
    }
  }
}
