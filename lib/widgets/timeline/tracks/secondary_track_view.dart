import 'package:flutter/material.dart';
import '../../../models/timeline_clip.dart';
import '../../../state/editor_controller.dart';
import '../../../theme/app_theme.dart';
import '../timeline_clip_widget.dart';

class SecondaryTrackView extends StatelessWidget {
  final List<TimelineClip> clips;
  final double scale;
  final double totalWidth;
  final String trackLabel;
  final IconData? trackIcon;
  final double trackHeight;
  final EditorController controller;

  const SecondaryTrackView({
    super.key,
    required this.clips,
    required this.scale,
    required this.totalWidth,
    required this.trackLabel,
    this.trackIcon,
    required this.trackHeight,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: trackHeight,
      width: totalWidth,
      color: AppTheme.timelineTrack.withValues(alpha: 0.8),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trackIcon != null) ...[
                  Icon(
                    trackIcon,
                    size: 10,
                    color: AppTheme.textMuted.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  trackLabel,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted.withValues(alpha: 0.4),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          for (final clip in clips)
            TimelineClipWidget(
              clip: clip,
              scale: scale,
              height: trackHeight - 6,
              controller: controller,
            ),
        ],
      ),
    );
  }
}
