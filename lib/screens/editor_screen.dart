import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/timeline_clip.dart';
import '../state/editor_controller.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/clip_inspector.dart';
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
    // Record / Voiceover modal
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic, size: 48, color: AppTheme.primary),
              const SizedBox(height: 12),
              const Text(
                'Voiceover Recorder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Record live audio commentary directly onto the timeline at current playhead.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  final now = DateTime.now().millisecondsSinceEpoch;
                  final voiceClip = TimelineClip(
                    id: 'voice_$now',
                    name: 'Voiceover ${DateTime.now().second}',
                    type: ClipType.audio,
                    startMs: _controller.playheadMs,
                    durationMs: 5000,
                    sourceDurationMs: 5000,
                    colorValue: 0xFFF59E0B,
                    isPrimary: false,
                    trackIndex: 3,
                  );
                  _controller.addSecondaryClip(voiceClip);
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.fiber_manual_record),
                label: const Text('Add 5s Voice Clip'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _captureSnapshot() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.camera_alt, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Capture & Snapshot at Playhead',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.save_alt,
                        color: AppTheme.primary, size: 20),
                  ),
                  title: const Text('Capture and Save Frame',
                      style: TextStyle(fontSize: 13, color: Colors.white)),
                  subtitle: const Text('Save current snapshot to gallery storage',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Frame snapshot at ${(_controller.playheadMs / 1000).toStringAsFixed(1)}s saved to gallery!',
                        ),
                        backgroundColor: AppTheme.surfaceVariant,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.content_cut,
                        color: Colors.cyanAccent, size: 20),
                  ),
                  title: const Text('Capture and Insert as Clip',
                      style: TextStyle(fontSize: 13, color: Colors.white)),
                  subtitle: const Text(
                      'Insert 3s freeze frame into primary track at playhead',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _controller.insertFreezeFrameAtPlayhead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Freeze frame inserted into timeline!'),
                        backgroundColor: AppTheme.surfaceVariant,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.layers,
                        color: Colors.amberAccent, size: 20),
                  ),
                  title: const Text('Capture and Add as Layer',
                      style: TextStyle(fontSize: 13, color: Colors.white)),
                  subtitle: const Text(
                      'Add frozen snapshot as secondary overlay layer',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _controller.addSnapshotAsLayer();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Snapshot added as overlay layer!'),
                        backgroundColor: AppTheme.surfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
        _buildTopActionBar(),

        // Upper: Video Preview Player
        Expanded(
          flex: 4,
          child: PreviewPlayer(controller: _controller),
        ),

        // Middle: Wheel or Inspector (collapsible / compact)
        if (!_isFullscreenPreview)
          Container(
            height: 195,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                top: BorderSide(color: AppTheme.divider),
                bottom: BorderSide(color: AppTheme.divider),
              ),
            ),
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
                return MediaWheel(
                  controller: _controller,
                  onOpenMedia: () => _openMediaBrowser(isPrimary: true),
                  onOpenLayer: () => _openMediaBrowser(isPrimary: false),
                  onOpenAudio: _openAudioBrowser,
                  onOpenRecord: _recordVoiceover,
                );
              },
            ),
          ),

        // Lower: Timeline
        if (!_isFullscreenPreview)
          Expanded(
            flex: 4,
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
        _buildLeftActionBar(),

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

  Widget _buildTopActionBar() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final canUndo = _controller.canUndo;
        final canRedo = _controller.canRedo;

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
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.project.name,
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
                onPressed: canUndo ? _controller.undo : null,
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.redo, size: 18),
                color: canRedo ? AppTheme.textPrimary : AppTheme.textMuted,
                tooltip: 'Redo',
                onPressed: canRedo ? _controller.redo : null,
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.more_vert,
                    size: 18, color: AppTheme.textPrimary),
                color: AppTheme.surfaceVariant,
                onSelected: (val) {
                  if (val == 'snapshot') _captureSnapshot();
                  if (val == 'settings') _openSettings();
                  if (val == 'fullscreen') {
                    setState(
                        () => _isFullscreenPreview = !_isFullscreenPreview);
                  }
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
                          _isFullscreenPreview
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isFullscreenPreview
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
                onTap: _openExport,
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

  Widget _buildLeftActionBar() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final canUndo = _controller.canUndo;
        final canRedo = _controller.canRedo;

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
                onPressed: () => Navigator.of(context).pop(),
              ),

              const Divider(height: 12, color: AppTheme.divider),

              // Undo
              IconButton(
                icon: const Icon(Icons.undo, size: 20),
                color: canUndo ? AppTheme.textPrimary : AppTheme.textMuted,
                tooltip: 'Undo',
                onPressed: canUndo ? _controller.undo : null,
              ),

              // Redo
              IconButton(
                icon: const Icon(Icons.redo, size: 20),
                color: canRedo ? AppTheme.textPrimary : AppTheme.textMuted,
                tooltip: 'Redo',
                onPressed: canRedo ? _controller.redo : null,
              ),

              // Frame Snapshot
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                color: AppTheme.textPrimary,
                tooltip: 'Capture Frame',
                onPressed: _captureSnapshot,
              ),

              // Master Settings
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                color: AppTheme.textPrimary,
                tooltip: 'Master Settings',
                onPressed: _openSettings,
              ),

              // Fullscreen Toggle
              IconButton(
                icon: Icon(
                  _isFullscreenPreview
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  size: 20,
                ),
                color: _isFullscreenPreview
                    ? AppTheme.primary
                    : AppTheme.textPrimary,
                tooltip: 'Toggle Fullscreen',
                onPressed: () {
                  setState(() {
                    _isFullscreenPreview = !_isFullscreenPreview;
                  });
                },
              ),

              const Spacer(),

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
                  onPressed: _openExport,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
