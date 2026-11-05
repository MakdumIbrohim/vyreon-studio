import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class KeyframeSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const KeyframeSection({
    super.key,
    required this.controller,
    required this.clip,
  });

  @override
  Widget build(BuildContext context) {
    final hasKeyNear = controller.hasKeyframeNearPlayhead(clip);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 18),
                tooltip: 'Previous Keyframe',
                onPressed: clip.keyframes.isEmpty
                    ? null
                    : () => controller.jumpToPreviousKeyframe(clip.id),
              ),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      controller.toggleKeyframeAtPlayhead(clip.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasKeyNear
                        ? Colors.redAccent
                        : AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: Icon(
                    hasKeyNear ? Icons.remove : Icons.add,
                    size: 16,
                  ),
                  label: Text(
                    hasKeyNear ? 'Remove' : 'Add Keyframe',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 18),
                tooltip: 'Next Keyframe',
                onPressed: clip.keyframes.isEmpty
                    ? null
                    : () => controller.jumpToNextKeyframe(clip.id),
              ),
            ],
          ),
        ),
        if (clip.keyframes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              '${clip.keyframes.length} keyframes active',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}
