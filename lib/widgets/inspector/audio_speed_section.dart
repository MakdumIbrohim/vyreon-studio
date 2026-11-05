import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';
import 'inspector_slider.dart';
import 'speed_ramp_section.dart';

class AudioSpeedSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const AudioSpeedSection({
    super.key,
    required this.controller,
    required this.clip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InspectorSlider(
          label: 'Volume',
          value: clip.volume * 100,
          min: 0.0,
          max: 200.0,
          onChanged: (val) =>
              controller.updateClip(clip.copyWith(volume: val / 100.0)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mute Audio',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            Switch(
              value: clip.isMuted,
              activeTrackColor: AppTheme.primary,
              onChanged: (val) =>
                  controller.updateClip(clip.copyWith(isMuted: val)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Playback Speed',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          children: [0.25, 0.5, 1.0, 1.5, 2.0, 4.0].map((s) {
            final isSel = (clip.speed - s).abs() < 0.05;
            return InkWell(
              onTap: () => controller.updateClip(clip.copyWith(speed: s)),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isSel ? AppTheme.primary : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${s}x',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        SpeedRampSection(controller: controller, clip: clip),
      ],
    );
  }
}
