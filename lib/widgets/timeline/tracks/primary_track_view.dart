import 'package:flutter/material.dart';
import '../../../models/timeline_clip.dart';
import '../../../state/editor_controller.dart';
import '../../../theme/app_theme.dart';
import '../timeline_clip_widget.dart';

class PrimaryTrackView extends StatelessWidget {
  final List<TimelineClip> clips;
  final double scale;
  final double totalWidth;
  final EditorController controller;
  final ValueChanged<TimelineClip> onEditTransition;

  const PrimaryTrackView({
    super.key,
    required this.clips,
    required this.scale,
    required this.totalWidth,
    required this.controller,
    required this.onEditTransition,
  });

  double _msToPx(int ms, double scale) => (ms / 1000.0) * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      width: totalWidth,
      color: AppTheme.timelineTrack,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 2,
            child: Text(
              'PRIMARY MEDIA TRACK',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted.withValues(alpha: 0.3),
              ),
            ),
          ),
          for (int i = 0; i < clips.length; i++) ...[
            TimelineClipWidget(
              clip: clips[i],
              scale: scale,
              height: 52,
              controller: controller,
            ),
            if (i < clips.length - 1)
              Positioned(
                left: _msToPx(clips[i].endMs, scale) - 9,
                top: 17,
                child: GestureDetector(
                  onTap: () => onEditTransition(clips[i + 1]),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: clips[i + 1].transition != TransitionType.none
                          ? AppTheme.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      clips[i + 1].transition != TransitionType.none
                          ? clips[i + 1].transition.icon
                          : Icons.change_circle,
                      size: 13,
                      color: clips[i + 1].transition != TransitionType.none
                          ? Colors.white
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
