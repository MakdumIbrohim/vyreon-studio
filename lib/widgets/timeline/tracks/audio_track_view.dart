import 'package:flutter/material.dart';
import '../../../models/timeline_clip.dart';
import '../../../state/editor_controller.dart';
import '../../../theme/app_theme.dart';
import '../timeline_clip_widget.dart';

class AudioTrackView extends StatelessWidget {
  final List<TimelineClip> clips;
  final double scale;
  final double totalWidth;
  final EditorController controller;

  const AudioTrackView({
    super.key,
    required this.clips,
    required this.scale,
    required this.totalWidth,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      width: totalWidth,
      color: AppTheme.timelineTrack.withValues(alpha: 0.6),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 2,
            child: Text(
              'AUDIO TRACK',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted.withValues(alpha: 0.25),
              ),
            ),
          ),
          for (final clip in clips)
            TimelineClipWidget(
              clip: clip,
              scale: scale,
              height: 32,
              isAudio: true,
              controller: controller,
            ),
        ],
      ),
    );
  }
}
