import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class ClipManagementSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const ClipManagementSection({
    super.key,
    required this.controller,
    required this.clip,
  });

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: AppTheme.surfaceVariant,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color ?? AppTheme.textPrimary),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.copy,
            label: 'Duplicate',
            onTap: () => controller.duplicateClip(clip.id),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.layers,
            label: 'As Layer',
            onTap: () => controller.duplicateAsLayer(clip.id),
          ),
        ),
        if (clip.type == ClipType.video) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              icon: Icons.fast_rewind,
              label: 'Reverse',
              onTap: () async {
                final success = await controller.reverseClip(clip.id);
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video playback reversed successfully!'),
                      backgroundColor: AppTheme.surfaceVariant,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              icon: Icons.music_note,
              label: 'Extract Audio',
              onTap: () async {
                final audio = await controller.extractAudioFromClip(clip.id);
                if (context.mounted && audio != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Audio extracted to timeline track!'),
                      backgroundColor: AppTheme.surfaceVariant,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}
