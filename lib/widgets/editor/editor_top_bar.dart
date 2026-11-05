import 'package:flutter/material.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class EditorTopBar extends StatelessWidget {
  final EditorController controller;
  final String projectName;
  final bool isFullscreenPreview;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onCaptureSnapshot;
  final VoidCallback onOpenSubtitles;
  final VoidCallback onOpenAudioMixer;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenExport;
  final VoidCallback onBack;

  const EditorTopBar({
    super.key,
    required this.controller,
    required this.projectName,
    required this.isFullscreenPreview,
    required this.onToggleFullscreen,
    required this.onCaptureSnapshot,
    required this.onOpenSubtitles,
    required this.onOpenAudioMixer,
    required this.onOpenSettings,
    required this.onOpenExport,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final canUndo = controller.canUndo;
        final canRedo = controller.canRedo;

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              bottom: BorderSide(color: AppTheme.divider, width: 1),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.arrow_back, size: 20),
                color: AppTheme.textPrimary,
                tooltip: 'Back to Projects',
                onPressed: onBack,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  projectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.undo, size: 18),
                color: canUndo ? AppTheme.textPrimary : AppTheme.textMuted,
                tooltip: 'Undo',
                onPressed: canUndo ? controller.undo : null,
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.redo, size: 18),
                color: canRedo ? AppTheme.textPrimary : AppTheme.textMuted,
                tooltip: 'Redo',
                onPressed: canRedo ? controller.redo : null,
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.more_vert,
                    size: 18, color: AppTheme.textPrimary),
                color: AppTheme.surfaceVariant,
                onSelected: (val) {
                  if (val == 'snapshot') onCaptureSnapshot();
                  if (val == 'subtitles') onOpenSubtitles();
                  if (val == 'mixer') onOpenAudioMixer();
                  if (val == 'settings') onOpenSettings();
                  if (val == 'fullscreen') onToggleFullscreen();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'snapshot',
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Capture Frame',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'subtitles',
                    child: Row(
                      children: [
                        Icon(Icons.subtitles_outlined,
                            size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Subtitles & SRT',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'mixer',
                    child: Row(
                      children: [
                        Icon(Icons.tune,
                            size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Audio Master Mixer',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined,
                            size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Master Settings',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'fullscreen',
                    child: Row(
                      children: [
                        Icon(
                          isFullscreenPreview
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFullscreenPreview
                              ? 'Exit Fullscreen'
                              : 'Fullscreen Preview',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onOpenExport,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.file_upload_outlined,
                          size: 15, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Export',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
