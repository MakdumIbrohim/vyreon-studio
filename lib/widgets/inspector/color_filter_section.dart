import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';
import 'inspector_slider.dart';

class ColorFilterSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const ColorFilterSection({
    super.key,
    required this.controller,
    required this.clip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ColorFilterPreset.values.map((preset) {
              final isSelected = clip.filter == preset;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(
                    preset.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceVariant,
                  onSelected: (_) =>
                      controller.updateClip(clip.copyWith(filter: preset)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Vignette Effect Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cinematic Vignette',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Switch(
                    value: clip.isVignetteEnabled,
                    activeTrackColor: AppTheme.primary,
                    onChanged: (val) => controller.updateClip(
                      clip.copyWith(isVignetteEnabled: val),
                    ),
                  ),
                ],
              ),
              if (clip.isVignetteEnabled) ...[
                const SizedBox(height: 6),
                InspectorSlider(
                  label: 'Intensity',
                  value: clip.vignetteIntensity * 100,
                  min: 10.0,
                  max: 100.0,
                  onChanged: (val) => controller.updateClip(
                    clip.copyWith(vignetteIntensity: val / 100.0),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
