import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class TrimSplitToolbar extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const TrimSplitToolbar({
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
            icon: Icons.cut,
            label: 'Split',
            onTap: () => controller.splitClipAtPlayhead(clip.id),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildActionButton(
            icon: Icons.keyboard_tab,
            label: 'Trim L',
            onTap: () => controller.trimClipLeft(clip.id),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildActionButton(
            icon: Icons.east,
            label: 'Trim R',
            onTap: () => controller.trimClipRight(clip.id),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildActionButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: Colors.redAccent,
            onTap: () => controller.deleteClip(clip.id),
          ),
        ),
      ],
    );
  }
}
