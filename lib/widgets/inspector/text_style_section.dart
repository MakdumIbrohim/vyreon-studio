import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';
import 'inspector_slider.dart';

class TextStyleSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const TextStyleSection({
    super.key,
    required this.controller,
    required this.clip,
  });

  Widget _buildColorChip({
    required int selectedColor,
    required int colorVal,
    required String label,
    required ValueChanged<int> onSelect,
  }) {
    final isSel = selectedColor == colorVal;
    return InkWell(
      onTap: () => onSelect(colorVal),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Color(colorVal).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSel ? Colors.white : Color(colorVal).withValues(alpha: 0.6),
            width: isSel ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(colorVal),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outline / Stroke
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Text Outline',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Switch(
                value: clip.isTextOutlineEnabled,
                activeTrackColor: AppTheme.primary,
                onChanged: (val) => controller.updateClip(
                  clip.copyWith(isTextOutlineEnabled: val),
                ),
              ),
            ],
          ),
          if (clip.isTextOutlineEnabled) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                _buildColorChip(
                  selectedColor: clip.textOutlineColor,
                  colorVal: 0xFF000000,
                  label: 'Black',
                  onSelect: (c) => controller.updateClip(clip.copyWith(textOutlineColor: c)),
                ),
                const SizedBox(width: 6),
                _buildColorChip(
                  selectedColor: clip.textOutlineColor,
                  colorVal: 0xFFFFFFFF,
                  label: 'White',
                  onSelect: (c) => controller.updateClip(clip.copyWith(textOutlineColor: c)),
                ),
                const SizedBox(width: 6),
                _buildColorChip(
                  selectedColor: clip.textOutlineColor,
                  colorVal: 0xFFFF334B,
                  label: 'Coral',
                  onSelect: (c) => controller.updateClip(clip.copyWith(textOutlineColor: c)),
                ),
                const SizedBox(width: 6),
                _buildColorChip(
                  selectedColor: clip.textOutlineColor,
                  colorVal: 0xFFFFD700,
                  label: 'Gold',
                  onSelect: (c) => controller.updateClip(clip.copyWith(textOutlineColor: c)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InspectorSlider(
              label: 'Outline Width',
              value: clip.textOutlineWidth,
              min: 1.0,
              max: 10.0,
              onChanged: (val) => controller.updateClip(clip.copyWith(textOutlineWidth: val)),
            ),
            const Divider(height: 12, color: AppTheme.divider),
          ],

          // Shadow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Text Shadow',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Switch(
                value: clip.isTextShadowEnabled,
                activeTrackColor: AppTheme.primary,
                onChanged: (val) => controller.updateClip(
                  clip.copyWith(isTextShadowEnabled: val),
                ),
              ),
            ],
          ),
          if (clip.isTextShadowEnabled) ...[
            const SizedBox(height: 4),
            InspectorSlider(
              label: 'Shadow Softness',
              value: clip.textShadowBlur,
              min: 1.0,
              max: 20.0,
              onChanged: (val) => controller.updateClip(clip.copyWith(textShadowBlur: val)),
            ),
            const Divider(height: 12, color: AppTheme.divider),
          ],

          // Glow Effect
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Neon Glow',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Switch(
                value: clip.isTextGlowEnabled,
                activeTrackColor: Colors.amber,
                onChanged: (val) => controller.updateClip(
                  clip.copyWith(isTextGlowEnabled: val),
                ),
              ),
            ],
          ),
          if (clip.isTextGlowEnabled) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                _buildColorChip(
                  selectedColor: clip.textGlowColor,
                  colorVal: 0xFFFFD700,
                  label: 'Gold',
                  onSelect: (c) => controller.updateClip(clip.copyWith(textGlowColor: c)),
                ),
                const SizedBox(width: 6),
                _buildColorChip(
                  selectedColor: clip.textGlowColor,
                  colorVal: 0xFF00FFFF,
                  label: 'Cyan',
                  onSelect: (c) => controller.updateClip(clip.copyWith(textGlowColor: c)),
                ),
                const SizedBox(width: 6),
                _buildColorChip(
                  selectedColor: clip.textGlowColor,
                  colorVal: 0xFFFF00FF,
                  label: 'Magenta',
                  onSelect: (c) => controller.updateClip(clip.copyWith(textGlowColor: c)),
                ),
                const SizedBox(width: 6),
                _buildColorChip(
                  selectedColor: clip.textGlowColor,
                  colorVal: 0xFF00FF66,
                  label: 'Lime',
                  onSelect: (c) => controller.updateClip(clip.copyWith(textGlowColor: c)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InspectorSlider(
              label: 'Glow Radius',
              value: clip.textGlowRadius,
              min: 4.0,
              max: 30.0,
              onChanged: (val) => controller.updateClip(clip.copyWith(textGlowRadius: val)),
            ),
          ],
        ],
      ),
    );
  }
}
