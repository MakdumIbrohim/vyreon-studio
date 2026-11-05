import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';
import 'inspector_slider.dart';

class VolumeEnvelopeSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const VolumeEnvelopeSection({
    super.key,
    required this.controller,
    required this.clip,
  });

  @override
  Widget build(BuildContext context) {
    final relMs =
        (controller.playheadMs - clip.startMs).clamp(0, clip.durationMs);

    // Find if there's a volume point near playhead (within 200ms)
    final existingPointIdx = clip.volumeEnvelope
        .indexWhere((p) => (p.timeMs - relMs).abs() <= 200);
    final hasPointNear = existingPointIdx >= 0;
    final currentPointVol =
        hasPointNear ? clip.volumeEnvelope[existingPointIdx].volume : 1.0;

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
          // 1. AUTO DUCKING
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.record_voice_over,
                      size: 16, color: Colors.amberAccent),
                  SizedBox(width: 6),
                  Text(
                    'Auto-Ducking',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: clip.isDuckingEnabled,
                activeTrackColor: Colors.amberAccent,
                onChanged: (val) {
                  controller.updateClip(
                    clip.copyWith(isDuckingEnabled: val),
                  );
                },
              ),
            ],
          ),
          if (clip.isDuckingEnabled) ...[
            const SizedBox(height: 4),
            InspectorSlider(
              label: 'Ducked BGM Level',
              value: clip.duckingLevel * 100,
              min: 5.0,
              max: 50.0,
              onChanged: (val) {
                controller.updateClip(
                  clip.copyWith(duckingLevel: val / 100.0),
                );
              },
            ),
            const Divider(height: 12, color: AppTheme.divider),
          ],

          // 2. VOLUME ENVELOPE (Keyframing Volume)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.graphic_eq, size: 16, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text(
                    'Volume Envelope',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${clip.volumeEnvelope.length} points',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasPointNear
                        ? Colors.redAccent.withValues(alpha: 0.25)
                        : AppTheme.primary.withValues(alpha: 0.25),
                    foregroundColor:
                        hasPointNear ? Colors.redAccent : AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 0,
                  ),
                  icon: Icon(
                    hasPointNear ? Icons.remove_circle : Icons.add_circle,
                    size: 15,
                  ),
                  label: Text(
                    hasPointNear ? 'Remove Point' : 'Add Point at Playhead',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onPressed: () {
                    final points =
                        List<VolumePoint>.from(clip.volumeEnvelope);
                    if (hasPointNear) {
                      points.removeAt(existingPointIdx);
                    } else {
                      points.add(VolumePoint(
                        timeMs: relMs,
                        volume: clip.volume,
                      ));
                      points.sort((a, b) => a.timeMs.compareTo(b.timeMs));
                    }
                    controller.updateClip(clip.copyWith(volumeEnvelope: points));
                  },
                ),
              ),
            ],
          ),
          if (hasPointNear) ...[
            const SizedBox(height: 6),
            InspectorSlider(
              label: 'Point Volume',
              value: currentPointVol * 100,
              min: 0.0,
              max: 200.0,
              onChanged: (val) {
                final points = List<VolumePoint>.from(clip.volumeEnvelope);
                points[existingPointIdx] = points[existingPointIdx]
                    .copyWith(volume: val / 100.0);
                controller.updateClip(clip.copyWith(volumeEnvelope: points));
              },
            ),
          ],
        ],
      ),
    );
  }
}
