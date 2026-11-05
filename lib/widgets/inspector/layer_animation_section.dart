import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';
import 'inspector_slider.dart';

class LayerAnimationSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const LayerAnimationSection({
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
          // 1. IN-ANIMATION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.login, size: 15, color: Colors.cyanAccent),
                  SizedBox(width: 6),
                  Text(
                    'In-Animation',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                clip.inAnimation.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: InAnimationType.values.map((anim) {
                final isSel = clip.inAnimation == anim;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      anim.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: Colors.cyan.shade700,
                    backgroundColor: AppTheme.surfaceVariant,
                    onSelected: (_) => controller.updateClip(
                      clip.copyWith(inAnimation: anim),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (clip.inAnimation != InAnimationType.none) ...[
            const SizedBox(height: 6),
            InspectorSlider(
              label: 'In Duration',
              value: clip.inDurationMs / 1000.0,
              min: 0.2,
              max: 3.0,
              onChanged: (val) => controller.updateClip(
                clip.copyWith(inDurationMs: (val * 1000).round()),
              ),
            ),
          ],

          const Divider(height: 14, color: AppTheme.divider),

          // 2. OVERALL-ANIMATION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.motion_photos_on_outlined,
                      size: 15, color: Colors.amberAccent),
                  SizedBox(width: 6),
                  Text(
                    'Overall Animation',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                clip.overallAnimation.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.amberAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: OverallAnimationType.values.map((anim) {
                final isSel = clip.overallAnimation == anim;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      anim.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: Colors.amber.shade700,
                    backgroundColor: AppTheme.surfaceVariant,
                    onSelected: (_) => controller.updateClip(
                      clip.copyWith(overallAnimation: anim),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 14, color: AppTheme.divider),

          // 3. OUT-ANIMATION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.logout, size: 15, color: Colors.pinkAccent),
                  SizedBox(width: 6),
                  Text(
                    'Out-Animation',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                clip.outAnimation.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: OutAnimationType.values.map((anim) {
                final isSel = clip.outAnimation == anim;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      anim.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: Colors.pink.shade700,
                    backgroundColor: AppTheme.surfaceVariant,
                    onSelected: (_) => controller.updateClip(
                      clip.copyWith(outAnimation: anim),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (clip.outAnimation != OutAnimationType.none) ...[
            const SizedBox(height: 6),
            InspectorSlider(
              label: 'Out Duration',
              value: clip.outDurationMs / 1000.0,
              min: 0.2,
              max: 3.0,
              onChanged: (val) => controller.updateClip(
                clip.copyWith(outDurationMs: (val * 1000).round()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
