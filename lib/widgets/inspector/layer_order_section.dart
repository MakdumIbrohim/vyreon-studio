import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class LayerOrderSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const LayerOrderSection({
    super.key,
    required this.controller,
    required this.clip,
  });

  @override
  Widget build(BuildContext context) {
    if (clip.isPrimary) return const SizedBox.shrink();

    final secondaries = controller.project.secondaryClips;
    final currentIndex = secondaries.indexWhere((c) => c.id == clip.id);

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
                  Icon(Icons.layers, size: 16, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text(
                    'Layer Order (Z-Index)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'Layer ${currentIndex + 1} of ${secondaries.length}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: const BorderSide(color: AppTheme.divider),
                  ),
                  icon: const Icon(Icons.vertical_align_top,
                      size: 14, color: Colors.cyanAccent),
                  label: const Text('Bring to Front',
                      style: TextStyle(fontSize: 10, color: Colors.white)),
                  onPressed: () => controller.bringToFront(clip.id),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: const BorderSide(color: AppTheme.divider),
                  ),
                  icon: const Icon(Icons.vertical_align_bottom,
                      size: 14, color: Colors.amberAccent),
                  label: const Text('Send to Back',
                      style: TextStyle(fontSize: 10, color: Colors.white)),
                  onPressed: () => controller.sendToBack(clip.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: const BorderSide(color: AppTheme.divider),
                  ),
                  icon: const Icon(Icons.arrow_upward,
                      size: 14, color: Colors.white70),
                  label: const Text('Move Forward',
                      style: TextStyle(fontSize: 10, color: Colors.white)),
                  onPressed: currentIndex < secondaries.length - 1
                      ? () => controller.reorderSecondaryClips(
                            currentIndex,
                            currentIndex + 2,
                          )
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: const BorderSide(color: AppTheme.divider),
                  ),
                  icon: const Icon(Icons.arrow_downward,
                      size: 14, color: Colors.white70),
                  label: const Text('Move Backward',
                      style: TextStyle(fontSize: 10, color: Colors.white)),
                  onPressed: currentIndex > 0
                      ? () => controller.reorderSecondaryClips(
                            currentIndex,
                            currentIndex - 1,
                          )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
