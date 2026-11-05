import 'package:flutter/material.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class EditorSideBar extends StatelessWidget {
  final EditorController controller;
  final bool isFullscreenPreview;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onCaptureSnapshot;
  final VoidCallback onOpenSubtitles;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenExport;
  final VoidCallback onBack;

  const EditorSideBar({
    super.key,
    required this.controller,
    required this.isFullscreenPreview,
    required this.onToggleFullscreen,
    required this.onCaptureSnapshot,
    required this.onOpenSubtitles,
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
          width: 52,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              right: BorderSide(color: AppTheme.divider, width: 1),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 6),
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                color: AppTheme.textPrimary,
                tooltip: 'Back to Projects',
                onPressed: onBack,
              ),

              const Divider(height: 12, color: AppTheme.divider),

              // Scrollable Actions
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Undo
                      IconButton(
                        icon: const Icon(Icons.undo, size: 20),
                        color: canUndo
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                        tooltip: 'Undo',
                        onPressed: canUndo ? controller.undo : null,
                      ),

                      // Redo
                      IconButton(
                        icon: const Icon(Icons.redo, size: 20),
                        color: canRedo
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                        tooltip: 'Redo',
                        onPressed: canRedo ? controller.redo : null,
                      ),

                      // Frame Snapshot
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, size: 20),
                        color: AppTheme.textPrimary,
                        tooltip: 'Capture Frame',
                        onPressed: onCaptureSnapshot,
                      ),

                      // Subtitles & SRT
                      IconButton(
                        icon: const Icon(Icons.subtitles_outlined, size: 20),
                        color: AppTheme.textPrimary,
                        tooltip: 'Subtitles & SRT',
                        onPressed: onOpenSubtitles,
                      ),

                      // Master Settings
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 20),
                        color: AppTheme.textPrimary,
                        tooltip: 'Master Settings',
                        onPressed: onOpenSettings,
                      ),

                      // Fullscreen Toggle
                      IconButton(
                        icon: Icon(
                          isFullscreenPreview
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          size: 20,
                        ),
                        color: isFullscreenPreview
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                        tooltip: 'Toggle Fullscreen',
                        onPressed: onToggleFullscreen,
                      ),
                    ],
                  ),
                ),
              ),

              // Export / Render Button (Bottom of Action Bar)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.file_upload_outlined,
                      size: 20, color: Colors.white),
                  tooltip: 'Export Video',
                  onPressed: onOpenExport,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
