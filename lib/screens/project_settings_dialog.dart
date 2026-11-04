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

  @override
  void initState() {
    super.initState();
    _defaultPhotoDuration = widget.settings.defaultPhotoDuration;
    _defaultTransitionDuration = widget.settings.defaultTransitionDuration;
    _audioFadeIn = widget.settings.audioFadeInDuration;
    _audioFadeOut = widget.settings.audioFadeOutDuration;
    _autoMasterVolume = widget.settings.autoMasterVolume;
  }

  void _save() {
    final updated = widget.settings.copyWith(
      defaultPhotoDuration: _defaultPhotoDuration,
      defaultTransitionDuration: _defaultTransitionDuration,
      audioFadeInDuration: _audioFadeIn,
      audioFadeOutDuration: _audioFadeOut,
      autoMasterVolume: _autoMasterVolume,
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
                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
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
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text('${_audioFadeIn.toStringAsFixed(1)}s',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
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
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text('${_audioFadeOut.toStringAsFixed(1)}s',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
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
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text('${_defaultPhotoDuration.toStringAsFixed(1)}s',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                ],
              ),
              Slider(
                value: _defaultPhotoDuration,
                min: 1.0,
                max: 15.0,
                onChanged: (val) =>
                    setState(() => _defaultPhotoDuration = val),
              ),

              const SizedBox(height: 16),

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
    );
  }
}
