import 'package:flutter/material.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class TimelineZoomToolbar extends StatelessWidget {
  final EditorController controller;
  final double scale;

  const TimelineZoomToolbar({
    super.key,
    required this.controller,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: AppTheme.surface,
      child: Row(
        children: [
          const Icon(Icons.timeline, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          const Text(
            'TIMELINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          // Zoom Out
          InkWell(
            onTap: () => controller.setTimelineScale(scale - 15.0),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child:
                  Icon(Icons.zoom_out, size: 18, color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(width: 4),
          // Zoom Slider
          SizedBox(
            width: 90,
            child: Slider(
              value: scale,
              min: 20.0,
              max: 180.0,
              onChanged: (val) => controller.setTimelineScale(val),
            ),
          ),
          const SizedBox(width: 4),
          // Zoom In
          InkWell(
            onTap: () => controller.setTimelineScale(scale + 15.0),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child:
                  Icon(Icons.zoom_in, size: 18, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
