import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class VoiceoverModalSheet extends StatelessWidget {
  final EditorController controller;

  const VoiceoverModalSheet({super.key, required this.controller});

  static void show(BuildContext context, EditorController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => VoiceoverModalSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, size: 48, color: AppTheme.primary),
          const SizedBox(height: 12),
          const Text(
            'Voiceover Recorder',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Record live audio commentary directly onto the timeline at current playhead.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              final now = DateTime.now().millisecondsSinceEpoch;
              final voiceClip = TimelineClip(
                id: 'voice_$now',
                name: 'Voiceover ${DateTime.now().second}',
                type: ClipType.audio,
                startMs: controller.playheadMs,
                durationMs: 5000,
                sourceDurationMs: 5000,
                colorValue: 0xFFF59E0B,
                isPrimary: false,
                trackIndex: 3,
              );
              controller.addSecondaryClip(voiceClip);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.fiber_manual_record),
            label: const Text('Add 5s Voice Clip'),
          ),
        ],
      ),
    );
  }
}
