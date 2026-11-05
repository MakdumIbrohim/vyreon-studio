import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class PipSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const PipSection({
    super.key,
    required this.controller,
    required this.clip,
  });

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
              const Row(
                children: [
                  Icon(Icons.picture_in_picture_alt,
                      size: 16, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text(
                    'Split Screen / PiP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (clip.pipPreset != PipPreset.none)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 24),
                  ),
                  onPressed: () =>
                      controller.applyPipPreset(clip.id, PipPreset.none),
                  child: const Text('Reset',
                      style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PipPreset.values.map((preset) {
                final isSel = clip.pipPreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      preset.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surfaceVariant,
                    onSelected: (_) =>
                        controller.applyPipPreset(clip.id, preset),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
