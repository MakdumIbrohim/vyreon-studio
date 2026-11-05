import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';
import 'inspector_slider.dart';

class PanZoomSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const PanZoomSection({
    super.key,
    required this.controller,
    required this.clip,
  });

  @override
  Widget build(BuildContext context) {
    final pz = clip.panZoom;

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
                  Icon(Icons.zoom_out_map, size: 16, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text(
                    'Pan & Zoom (Ken Burns)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: pz.isEnabled,
                activeTrackColor: AppTheme.primary,
                onChanged: (val) {
                  controller.updateClip(
                    clip.copyWith(panZoom: pz.copyWith(isEnabled: val)),
                  );
                },
              ),
            ],
          ),
          if (pz.isEnabled) ...[
            const SizedBox(height: 6),
            const Text(
              'START POSITION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
                letterSpacing: 0.5,
              ),
            ),
            InspectorSlider(
              label: 'Start Scale',
              value: pz.startScale,
              min: 0.8,
              max: 2.5,
              onChanged: (val) {
                controller.updateClip(
                  clip.copyWith(panZoom: pz.copyWith(startScale: val)),
                );
              },
            ),
            const Divider(height: 12, color: AppTheme.divider),
            const Text(
              'END POSITION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.amberAccent,
                letterSpacing: 0.5,
              ),
            ),
            InspectorSlider(
              label: 'End Scale',
              value: pz.endScale,
              min: 0.8,
              max: 2.5,
              onChanged: (val) {
                controller.updateClip(
                  clip.copyWith(panZoom: pz.copyWith(endScale: val)),
                );
              },
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      side: const BorderSide(color: AppTheme.divider),
                    ),
                    icon: const Icon(Icons.zoom_in, size: 14, color: Colors.white70),
                    label: const Text('Zoom In', style: TextStyle(fontSize: 10, color: Colors.white)),
                    onPressed: () {
                      controller.updateClip(
                        clip.copyWith(
                          panZoom: pz.copyWith(
                            isEnabled: true,
                            startScale: 1.0,
                            endScale: 1.4,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      side: const BorderSide(color: AppTheme.divider),
                    ),
                    icon: const Icon(Icons.zoom_out, size: 14, color: Colors.white70),
                    label: const Text('Zoom Out', style: TextStyle(fontSize: 10, color: Colors.white)),
                    onPressed: () {
                      controller.updateClip(
                        clip.copyWith(
                          panZoom: pz.copyWith(
                            isEnabled: true,
                            startScale: 1.4,
                            endScale: 1.0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
