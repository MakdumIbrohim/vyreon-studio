import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/video_render_service.dart';
import '../theme/app_theme.dart';
import '../widgets/export/export_views.dart';

class ExportDialog extends StatefulWidget {
  final Project project;

  const ExportDialog({super.key, required this.project});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _selectedResolution = 'FHD 1080p';
  int _selectedFps = 30;
  double _bitrateMbps = 10.0;
  bool _isExporting = false;
  double _exportProgress = 0.0;
  bool _exportCompleted = false;
  String _exportedPath = '';
  int _exportedSize = 0;
  String? _exportError;

  final List<String> _resolutions = ['HD 720p', 'FHD 1080p', '4K 2160p'];
  final List<int> _frameRates = [24, 30, 60];

  double get _estimatedFileSizeMb {
    final durationSeconds = widget.project.totalDurationMs / 1000.0;
    return (_bitrateMbps * durationSeconds) / 8.0;
  }

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportError = null;
    });

    final result = await VideoRenderService.instance.renderProject(
      project: widget.project,
      resolution: _selectedResolution,
      fps: _selectedFps,
      bitrateMbps: _bitrateMbps,
      onProgress: (p) {
        if (mounted) {
          setState(() => _exportProgress = p);
        }
      },
    );

    if (mounted) {
      setState(() {
        _isExporting = false;
        if (result.success) {
          _exportCompleted = true;
          _exportedPath = result.outputPath;
          _exportedSize = result.fileSize;
        } else {
          _exportError = result.error ?? 'Export failed';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isExporting
              ? ExportProgressView(
                  progress: _exportProgress,
                  onCancel: () => setState(() => _isExporting = false),
                )
              : (_exportCompleted
                  ? ExportCompletedView(
                      resolution: _selectedResolution,
                      fileSize: _exportedSize,
                      outputPath: _exportedPath,
                      onDone: () => Navigator.of(context).pop(),
                    )
                  : ExportConfigView(
                      project: widget.project,
                      selectedResolution: _selectedResolution,
                      selectedFps: _selectedFps,
                      bitrateMbps: _bitrateMbps,
                      estimatedFileSizeMb: _estimatedFileSizeMb,
                      exportError: _exportError,
                      resolutions: _resolutions,
                      frameRates: _frameRates,
                      onSelectResolution: (res) =>
                          setState(() => _selectedResolution = res),
                      onSelectFps: (fps) => setState(() => _selectedFps = fps),
                      onChangeBitrate: (val) =>
                          setState(() => _bitrateMbps = val),
                      onStartExport: _startExport,
                    )),
        ),
      ),
    );
  }
}
