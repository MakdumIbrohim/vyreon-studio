import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../theme/app_theme.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onOpen;
  final VoidCallback onDuplicate;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onExportBundle;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onOpen,
    required this.onDuplicate,
    required this.onRename,
    required this.onDelete,
    required this.onExportBundle,
  });

  String _formatDuration(int ms) {
    final sec = ms ~/ 1000;
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final firstClip = project.clips.isNotEmpty ? project.clips.first : null;
    final thumbColor =
        firstClip != null ? firstClip.color : AppTheme.surfaceVariant;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail Area
            Expanded(
              flex: 5,
              child: Container(
                color: thumbColor,
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        project.aspectRatio.icon,
                        size: 32,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    // Aspect ratio tag
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          project.aspectRatio.label,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Duration badge
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(project.totalDurationMs),
                          style: const TextStyle(
                            fontSize: 9,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info Area
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${project.clips.length} clips • ${project.modifiedAt.month}/${project.modifiedAt.day}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          size: 16, color: AppTheme.textMuted),
                      color: AppTheme.surface,
                      onSelected: (action) {
                        if (action == 'open') onOpen();
                        if (action == 'duplicate') onDuplicate();
                        if (action == 'rename') onRename();
                        if (action == 'export_bundle') onExportBundle();
                        if (action == 'delete') onDelete();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'open',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Project'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 16),
                              SizedBox(width: 8),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.drive_file_rename_outline, size: 16),
                              SizedBox(width: 8),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export_bundle',
                          child: Row(
                            children: [
                              Icon(Icons.archive_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Export .vyreon Bundle'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete,
                                  size: 16, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
