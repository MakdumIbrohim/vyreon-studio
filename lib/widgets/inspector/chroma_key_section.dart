import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';
import 'inspector_slider.dart';

class ChromaKeySection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const ChromaKeySection({
    super.key,
    required this.controller,
    required this.clip,
  });

  Widget _buildKeyColorChip(String label, int colorVal) {
    final isSel = clip.chromaKeyColor == colorVal;
    return InkWell(
      onTap: () =>
          controller.updateClip(clip.copyWith(chromaKeyColor: colorVal)),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: Color(colorVal).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                isSel ? Colors.white : Color(colorVal).withValues(alpha: 0.5),
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
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enable Chroma Key',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Switch(
                value: clip.isChromaKeyEnabled,
                activeTrackColor: AppTheme.primary,
                onChanged: (val) => controller
                    .updateClip(clip.copyWith(isChromaKeyEnabled: val)),
              ),
            ],
          ),
          if (clip.isChromaKeyEnabled) ...[
            const SizedBox(height: 8),
            const Text(
              'Key Color:',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildKeyColorChip('Green', 0xFF00FF00),
                const SizedBox(width: 6),
                _buildKeyColorChip('Blue', 0xFF0000FF),
                const SizedBox(width: 6),
                _buildKeyColorChip('Cyan', 0xFF00FFFF),
                const SizedBox(width: 6),
                _buildKeyColorChip('Magenta', 0xFFFF00FF),
              ],
            ),
            const SizedBox(height: 10),
            InspectorSlider(
              label: 'Threshold (Similarity)',
              value: clip.chromaThreshold * 100,
              min: 5.0,
              max: 90.0,
              onChanged: (val) => controller
                  .updateClip(clip.copyWith(chromaThreshold: val / 100.0)),
            ),
            InspectorSlider(
              label: 'Detail (Smoothness)',
              value: clip.chromaSmoothness * 100,
              min: 0.0,
              max: 50.0,
              onChanged: (val) => controller
                  .updateClip(clip.copyWith(chromaSmoothness: val / 100.0)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Show B&W Mask',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Switch(
                  value: clip.chromaShowMask,
                  activeTrackColor: Colors.amber,
                  onChanged: (val) => controller
                      .updateClip(clip.copyWith(chromaShowMask: val)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
