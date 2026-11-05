import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class AudioDenoiseSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const AudioDenoiseSection({
    super.key,
    required this.controller,
    required this.clip,
  });

  @override
  Widget build(BuildContext context) {
    final isDenoiseActive = clip.denoisePreset != AudioDenoisePreset.none;
    final isEnhanceActive = clip.enhancePreset != AudioEnhancePreset.none;

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
          // -------------------------------------------------------------
          // 1. NOISE REDUCTION / DENOISE
          // -------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.hearing_disabled, size: 16, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text(
                    'Noise Suppression (Denoise)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDenoiseActive
                      ? AppTheme.primary.withValues(alpha: 0.2)
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  clip.denoisePreset.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDenoiseActive ? AppTheme.primary : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AudioDenoisePreset.values.map((preset) {
                final isSel = clip.denoisePreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(preset.label),
                    selected: isSel,
                    selectedColor: AppTheme.primary.withValues(alpha: 0.25),
                    backgroundColor: AppTheme.surfaceVariant,
                    labelStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? AppTheme.primary : AppTheme.textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(
                        color: isSel ? AppTheme.primary : AppTheme.divider,
                      ),
                    ),
                    onSelected: (_) {
                      controller.updateClip(clip.copyWith(denoisePreset: preset));
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            clip.denoisePreset.description,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),

          const SizedBox(height: 12),
          const Divider(color: AppTheme.divider, height: 1),
          const SizedBox(height: 10),

          // -------------------------------------------------------------
          // 2. AUDIO & VOCAL ENHANCER
          // -------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_fix_high, size: 16, color: Colors.cyanAccent),
                  SizedBox(width: 6),
                  Text(
                    'Voice Enhancer & Dynamics',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isEnhanceActive
                      ? Colors.cyanAccent.withValues(alpha: 0.2)
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  clip.enhancePreset.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isEnhanceActive ? Colors.cyanAccent : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AudioEnhancePreset.values.map((preset) {
                final isSel = clip.enhancePreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(preset.label),
                    selected: isSel,
                    selectedColor: Colors.cyanAccent.withValues(alpha: 0.25),
                    backgroundColor: AppTheme.surfaceVariant,
                    labelStyle: TextStyle(
                      fontSize: 10,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? Colors.cyanAccent : AppTheme.textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(
                        color: isSel ? Colors.cyanAccent : AppTheme.divider,
                      ),
                    ),
                    onSelected: (_) {
                      controller.updateClip(clip.copyWith(enhancePreset: preset));
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            clip.enhancePreset.description,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
