import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class AudioMasterMixerModalSheet extends StatefulWidget {
  final EditorController controller;

  const AudioMasterMixerModalSheet({super.key, required this.controller});

  static Future<void> show(BuildContext context, EditorController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AudioMasterMixerModalSheet(controller: controller),
    );
  }

  @override
  State<AudioMasterMixerModalSheet> createState() =>
      _AudioMasterMixerModalSheetState();
}

class _AudioMasterMixerModalSheetState
    extends State<AudioMasterMixerModalSheet> {
  late double _masterVolume;
  late bool _isMasterMuted;
  late bool _autoMasterVolume;
  late double _audioFadeInDuration;
  late double _audioFadeOutDuration;

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.project.settings;
    _masterVolume = settings.masterVolume;
    _isMasterMuted = settings.isMasterMuted;
    _autoMasterVolume = settings.autoMasterVolume;
    _audioFadeInDuration = settings.audioFadeInDuration;
    _audioFadeOutDuration = settings.audioFadeOutDuration;
  }

  void _applySettings() {
    final updated = widget.controller.project.settings.copyWith(
      masterVolume: _masterVolume,
      isMasterMuted: _isMasterMuted,
      autoMasterVolume: _autoMasterVolume,
      audioFadeInDuration: _audioFadeInDuration,
      audioFadeOutDuration: _audioFadeOutDuration,
    );
    widget.controller.updateSettings(updated);
  }

  @override
  Widget build(BuildContext context) {
    final audioClips = widget.controller.project.clips
        .where((c) => c.type == ClipType.audio)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.tune, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Audio Master Mixer',
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
              const SizedBox(height: 12),

              // Master Mute Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isMasterMuted
                              ? Icons.volume_off
                              : Icons.volume_up,
                          color: _isMasterMuted
                              ? Colors.redAccent
                              : AppTheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Mute All Project Audio',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isMasterMuted,
                      activeThumbColor: Colors.redAccent,
                      onChanged: (val) {
                        setState(() => _isMasterMuted = val);
                        _applySettings();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Master Volume Slider (0 - 200%)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MASTER OUTPUT VOLUME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    '${(_masterVolume * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _masterVolume,
                min: 0.0,
                max: 2.0,
                divisions: 40,
                onChanged: _isMasterMuted
                    ? null
                    : (val) {
                        setState(() => _masterVolume = val);
                        _applySettings();
                      },
              ),

              const SizedBox(height: 12),

              // Auto Master Volume
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Auto Master Volume',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
                subtitle: const Text(
                  'Automatically normalize audio track levels',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                value: _autoMasterVolume,
                activeThumbColor: AppTheme.primary,
                onChanged: (val) {
                  setState(() => _autoMasterVolume = val);
                  _applySettings();
                },
              ),

              const Divider(height: 16, color: AppTheme.divider),

              // Audio Fade In / Fade Out
              const Text(
                'PROJECT AUDIO ENVELOPE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),

              // Fade In
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Audio Fade In',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  Text('${_audioFadeInDuration.toStringAsFixed(1)}s',
                      style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppTheme.textPrimary)),
                ],
              ),
              Slider(
                value: _audioFadeInDuration,
                min: 0.0,
                max: 5.0,
                divisions: 50,
                onChanged: (val) {
                  setState(() => _audioFadeInDuration = val);
                  _applySettings();
                },
              ),

              // Fade Out
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Audio Fade Out',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  Text('${_audioFadeOutDuration.toStringAsFixed(1)}s',
                      style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppTheme.textPrimary)),
                ],
              ),
              Slider(
                value: _audioFadeOutDuration,
                min: 0.0,
                max: 5.0,
                divisions: 50,
                onChanged: (val) {
                  setState(() => _audioFadeOutDuration = val);
                  _applySettings();
                },
              ),

              const Divider(height: 16, color: AppTheme.divider),

              // Audio Tracks List Summary
              Row(
                children: [
                  const Icon(Icons.audiotrack, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Active Audio Clips (${audioClips.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (audioClips.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No audio clips currently in timeline.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                )
              else
                for (final clip in audioClips)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            clip.name,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(clip.volume * 100).round()}%',
                          style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: AppTheme.primary),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 28),
                          icon: Icon(
                            clip.isMuted
                                ? Icons.volume_off
                                : Icons.volume_up,
                            size: 16,
                            color: clip.isMuted
                                ? Colors.redAccent
                                : AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            widget.controller.updateClip(
                                clip.copyWith(isMuted: !clip.isMuted));
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
