import 'package:flutter/material.dart';
import '../models/aspect_ratio.dart';
import '../models/project.dart';
import '../models/project_settings.dart';
import '../models/timeline_clip.dart';
import '../theme/app_theme.dart';
import '../widgets/create_project/aspect_ratio_picker.dart';
import '../widgets/create_project/project_duration_options.dart';

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Untitled Project');
  ProjectAspectRatio _selectedRatio = ProjectAspectRatio.ratio16x9;
  double _defaultPhotoDuration = 4.5;
  double _defaultTransitionDuration = 1.5;
  bool _showAdvanced = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _create() {
    final now = DateTime.now();
    final name = _nameController.text.trim().isEmpty
        ? 'Untitled Project'
        : _nameController.text.trim();

    final project = Project(
      id: 'proj_${now.millisecondsSinceEpoch}',
      name: name,
      aspectRatio: _selectedRatio,
      createdAt: now,
      modifiedAt: now,
      settings: ProjectSettings(
        defaultPhotoDuration: _defaultPhotoDuration,
        defaultTransitionDuration: _defaultTransitionDuration,
      ),
      clips: [
        TimelineClip(
          id: 'clip_intro_${now.millisecondsSinceEpoch}',
          name: 'Intro Backdrop',
          type: ClipType.color,
          startMs: 0,
          durationMs: (_defaultPhotoDuration * 1000).round(),
          sourceDurationMs: (_defaultPhotoDuration * 1000).round(),
          colorValue: 0xFF1E293B,
          isPrimary: true,
        ),
      ],
    );

    Navigator.of(context).pop(project);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.video_call_rounded,
                      size: 26, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'New Project',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Project Name TextField
              TextField(
                controller: _nameController,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Project Name',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  prefixIcon: const Icon(Icons.edit,
                      size: 18, color: AppTheme.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'ASPECT RATIO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 8),

              // Aspect Ratio Grid / Wrap & Advanced Settings
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatioPicker(
                        selectedRatio: _selectedRatio,
                        onRatioSelected: (ratio) =>
                            setState(() => _selectedRatio = ratio),
                      ),
                      const SizedBox(height: 16),
                      ProjectDurationOptions(
                        isExpanded: _showAdvanced,
                        onToggle: () =>
                            setState(() => _showAdvanced = !_showAdvanced),
                        photoDuration: _defaultPhotoDuration,
                        onPhotoDurationChanged: (val) =>
                            setState(() => _defaultPhotoDuration = val),
                        transitionDuration: _defaultTransitionDuration,
                        onTransitionDurationChanged: (val) =>
                            setState(() => _defaultTransitionDuration = val),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _create,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Create',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
