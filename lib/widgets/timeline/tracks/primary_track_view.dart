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
          // 1. All Clips rendered first
          for (int i = 0; i < clips.length; i++)
            TimelineClipWidget(
              clip: clips[i],
              scale: scale,
              height: 52,
              controller: controller,
            ),

          // 2. Transition Buttons rendered ON TOP of clips, centered at the seam
          for (int i = 0; i < clips.length - 1; i++) ...[
            Builder(
              builder: (context) {
                final hasTransition =
                    clips[i + 1].transition != TransitionType.none;

                return Positioned(
                  left: _msToPx(clips[i].endMs, scale) - 11,
                  top: 17,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onEditTransition(clips[i + 1]),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: hasTransition
                            ? AppTheme.primary
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasTransition
                              ? Colors.white.withValues(alpha: 0.9)
                              : const Color(0xFF64748B),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 6,
                            spreadRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          hasTransition
                              ? clips[i + 1].transition.icon
                              : Icons.change_circle,
                          size: 14,
                          color: hasTransition
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
