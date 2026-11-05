import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/project_settings.dart';
import '../theme/app_theme.dart';

class ProjectSettingsDialog extends StatefulWidget {
  final ProjectSettings settings;

  const ProjectSettingsDialog({super.key, required this.settings});

  @override
  State<ProjectSettingsDialog> createState() => _ProjectSettingsDialogState();
}

class _ProjectSettingsDialogState extends State<ProjectSettingsDialog> {
  late double _defaultPhotoDuration;
  late double _defaultTransitionDuration;
  late double _audioFadeIn;
  late double _audioFadeOut;
  late bool _autoMasterVolume;
  String? _customExportDirectory;

  @override
  void initState() {
    super.initState();
    _defaultPhotoDuration = widget.settings.defaultPhotoDuration;
    _defaultTransitionDuration = widget.settings.defaultTransitionDuration;
    _audioFadeIn = widget.settings.audioFadeInDuration;
    _audioFadeOut = widget.settings.audioFadeOutDuration;
    _autoMasterVolume = widget.settings.autoMasterVolume;
    _customExportDirectory = widget.settings.customExportDirectory;
  }

  Future<void> _pickExportFolder() async {
    final selectedDir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select Video Export Folder',
    );
    if (selectedDir != null && selectedDir.isNotEmpty) {
      setState(() => _customExportDirectory = selectedDir);
    }
  }

  void _save() {
    final updated = widget.settings.copyWith(
      defaultPhotoDuration: _defaultPhotoDuration,
      defaultTransitionDuration: _defaultTransitionDuration,
      audioFadeInDuration: _audioFadeIn,
      audioFadeOutDuration: _audioFadeOut,
      autoMasterVolume: _autoMasterVolume,
      customExportDirectory: _customExportDirectory,
      clearCustomExportDirectory: _customExportDirectory == null,
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.tune, size: 22, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Project Master Settings',
                      style: TextStyle(
                        fontSize: 16,
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

                // Audio Section
                const Text(
                  'AUDIO MASTER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Auto Master Volume',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textPrimary)),
                    Switch(
                      value: _autoMasterVolume,
                      activeTrackColor: AppTheme.primary,
                      onChanged: (val) =>
                          setState(() => _autoMasterVolume = val),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Audio Fade-in',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text('${_audioFadeIn.toStringAsFixed(1)}s',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textPrimary)),
                  ],
                ),
                Slider(
                  value: _audioFadeIn,
                  min: 0.0,
                  max: 5.0,
                  onChanged: (val) => setState(() => _audioFadeIn = val),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Audio Fade-out',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text('${_audioFadeOut.toStringAsFixed(1)}s',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textPrimary)),
                  ],
                ),
                Slider(
                  value: _audioFadeOut,
                  min: 0.0,
                  max: 5.0,
                  onChanged: (val) => setState(() => _audioFadeOut = val),
                ),

                const SizedBox(height: 12),

                // Editing Section
                const Text(
                  'EDITING DEFAULTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Default Photo Duration',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text('${_defaultPhotoDuration.toStringAsFixed(1)}s',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textPrimary)),
                  ],
                ),
                Slider(
                  value: _defaultPhotoDuration,
                  min: 1.0,
                  max: 15.0,
                  onChanged: (val) =>
                      setState(() => _defaultPhotoDuration = val),
                ),

                const SizedBox(height: 12),

                // Export Folder Location Section
                const Text(
                  'EXPORT STORAGE LOCATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.folder_outlined,
                              size: 18, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _customExportDirectory ??
                                  'Default (~/Videos/VyreonStudio)',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: _customExportDirectory != null
                                    ? Colors.white
                                    : AppTheme.textMuted,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_customExportDirectory != null)
                            TextButton(
                              onPressed: () =>
                                  setState(() => _customExportDirectory = null),
                              child: const Text('Reset to Default',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary)),
                            ),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            onPressed: _pickExportFolder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surface,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.folder_open, size: 14),
                            label: const Text('Choose Folder',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Done Button
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save Settings',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
