import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/timeline_clip.dart';
import '../state/editor_controller.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/clip_inspector.dart';
import '../widgets/editor/audio_master_mixer_modal_sheet.dart';
import '../widgets/editor/editor_side_bar.dart';
import '../widgets/editor/editor_top_bar.dart';
import '../widgets/editor/snapshot_modal_sheet.dart';
import '../widgets/editor/subtitle_modal_sheet.dart';
import '../widgets/editor/voiceover_modal_sheet.dart';
import '../widgets/media_wheel.dart';
import '../widgets/preview_player.dart';
import '../widgets/timeline_view.dart';
import 'export_dialog.dart';
import 'media_browser_dialog.dart';
import 'project_settings_dialog.dart';

class EditorScreen extends StatefulWidget {
  final Project project;

  const EditorScreen({super.key, required this.project});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late EditorController _controller;
  bool _isFullscreenPreview = false;

  @override
  void initState() {
    super.initState();
    _controller = EditorController(widget.project);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openMediaBrowser({required bool isPrimary}) async {
    final clip = await showDialog<TimelineClip>(
      context: context,
      builder: (_) => MediaBrowserDialog(isPrimaryMode: isPrimary),
    );

    if (clip != null) {
      if (isPrimary) {
        _controller.addPrimaryClip(clip);
      } else {
        _controller.addSecondaryClip(clip);
      }
    }
  }

  Future<void> _openAudioBrowser() async {
    final clip = await showDialog<TimelineClip>(
      context: context,
      builder: (_) => const MediaBrowserDialog(isPrimaryMode: false),
    );
    if (clip != null) {
      _controller.addSecondaryClip(clip);
    }
  }

  void _recordVoiceover() {
    VoiceoverModalSheet.show(context, _controller);
  }

  void _captureSnapshot() {
    SnapshotModalSheet.show(context, _controller);
  }

  void _openSubtitles() {
    SubtitleModalSheet.show(context, _controller);
  }

  void _openAudioMixer() {
    AudioMasterMixerModalSheet.show(context, _controller);
  }

  Future<void> _openSettings() async {
    final updated = await showDialog(
      context: context,
      builder: (_) =>
          ProjectSettingsDialog(settings: _controller.project.settings),
    );
    if (updated != null) {
      _controller.updateSettings(updated);
    }
  }

  Future<void> _openExport() async {
    _controller.pause();
    await showDialog(
      context: context,
      builder: (_) => ExportDialog(project: _controller.project),
    );
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreenPreview = !_isFullscreenPreview);
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = ResponsiveLayout.isPortrait(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: isPortrait
            ? _buildPortraitLayout()
            : _buildLandscapeLayout(context),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        EditorTopBar(
          controller: _controller,
          projectName: widget.project.name,
          isFullscreenPreview: _isFullscreenPreview,
          onToggleFullscreen: _toggleFullscreen,
          onCaptureSnapshot: _captureSnapshot,
          onOpenSubtitles: _openSubtitles,
          onOpenAudioMixer: _openAudioMixer,
          onOpenSettings: _openSettings,
          onOpenExport: _openExport,
          onBack: () => Navigator.of(context).pop(),
        ),

        // Upper: Video Preview Player
        Expanded(
          flex: 4,
          child: PreviewPlayer(controller: _controller),
        ),

        // Middle: Wheel or Inspector (collapsible / compact)
        if (!_isFullscreenPreview)
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final selected = _controller.selectedClip;
              final isInspector = selected != null;
              final panelHeight = isInspector ? 240.0 : 185.0;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: panelHeight,
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(
                    top: BorderSide(color: AppTheme.divider),
                    bottom: BorderSide(color: AppTheme.divider),
                  ),
                ),
                child: isInspector
                    ? ClipInspector(
                        controller: _controller,
                        clip: selected,
                      )
                    : MediaWheel(
                        controller: _controller,
                        onOpenMedia: () => _openMediaBrowser(isPrimary: true),
                        onOpenLayer: () => _openMediaBrowser(isPrimary: false),
                        onOpenAudio: _openAudioBrowser,
                        onOpenRecord: _recordVoiceover,
                      ),
              );
            },
          ),

        // Lower: Timeline
        if (!_isFullscreenPreview)
          Expanded(
            flex: 5,
            child: TimelineView(controller: _controller),
          ),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    final panelWidth = ResponsiveLayout.getEditorPanelWidth(context);

    return Row(
      children: [
        // Left Action Bar (Vertical)
        EditorSideBar(
          controller: _controller,
          isFullscreenPreview: _isFullscreenPreview,
          onToggleFullscreen: _toggleFullscreen,
          onCaptureSnapshot: _captureSnapshot,
          onOpenSubtitles: _openSubtitles,
          onOpenAudioMixer: _openAudioMixer,
          onOpenSettings: _openSettings,
          onOpenExport: _openExport,
          onBack: () => Navigator.of(context).pop(),
        ),

        // Main Editor Space
        Expanded(
          child: Column(
            children: [
              // Upper Half: Preview & Control Panel / Dial
              Expanded(
                flex: 6,
                child: Row(
                  children: [
                    // Video Preview Player
                    Expanded(
                      flex: 7,
                      child: PreviewPlayer(controller: _controller),
                    ),

                    // Options / Wheel Panel (Right)
                    if (!_isFullscreenPreview)
                      SizedBox(
                        width: panelWidth,
                        child: ListenableBuilder(
                          listenable: _controller,
                          builder: (context, _) {
                            final selected = _controller.selectedClip;
                            if (selected != null) {
                              return ClipInspector(
                                controller: _controller,
                                clip: selected,
                              );
                            }
                            return Container(
                              color: AppTheme.surface,
                              child: MediaWheel(
                                controller: _controller,
                                onOpenMedia: () =>
                                    _openMediaBrowser(isPrimary: true),
                                onOpenLayer: () =>
                                    _openMediaBrowser(isPrimary: false),
                                onOpenAudio: _openAudioBrowser,
                                onOpenRecord: _recordVoiceover,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // Lower Half: Timeline
              if (!_isFullscreenPreview)
                Expanded(
                  flex: 4,
                  child: TimelineView(controller: _controller),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
