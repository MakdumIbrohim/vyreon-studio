import 'dart:async';
import 'package:flutter/material.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';

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
  Timer? _exportTimer;

  final List<String> _resolutions = ['HD 720p', 'FHD 1080p', '4K 2160p'];
  final List<int> _frameRates = [24, 30, 60];

  double get _estimatedFileSizeMb {
    final durationSeconds = widget.project.totalDurationMs / 1000.0;
    // Megabytes = (Mbps * duration) / 8
    return (_bitrateMbps * durationSeconds) / 8.0;
  }

  void _startExport() {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
    });

    _exportTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _exportProgress += 0.02;
        if (_exportProgress >= 1.0) {
          _exportProgress = 1.0;
          _isExporting = false;
          _exportCompleted = true;
          _exportTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _exportTimer?.cancel();
    super.dispose();
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
          child: _isExporting ? _buildExportingView() : (_exportCompleted ? _buildCompletedView() : _buildConfigView()),
        ),
      ),
    );
  }

  Widget _buildConfigView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Row(
          children: [
            const Icon(Icons.file_upload_outlined,
                size: 24, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text(
              'Save and Share Video',
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

        // Resolution Selector
        const Text('RESOLUTION',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted)),
        const SizedBox(height: 6),
        Row(
          children: _resolutions.map((res) {
            final isSel = _selectedResolution == res;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      res,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceVariant,
                  onSelected: (_) => setState(() => _selectedResolution = res),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),

        // Frame Rate Selector
        const Text('FRAME RATE',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted)),
        const SizedBox(height: 6),
        Row(
          children: _frameRates.map((fps) {
            final isSel = _selectedFps == fps;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      '$fps fps',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceVariant,
                  onSelected: (_) => setState(() => _selectedFps = fps),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),

        // Bitrate Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('QUALITY / BITRATE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted)),
            Text('${_bitrateMbps.toStringAsFixed(1)} Mbps',
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppTheme.textPrimary)),
          ],
        ),
        Slider(
          value: _bitrateMbps,
          min: 2.0,
          max: 30.0,
          onChanged: (val) => setState(() => _bitrateMbps = val),
        ),

        // Estimated File Size Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated File Size:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text(
                'About ${_estimatedFileSizeMb.toStringAsFixed(1)} MB',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Save as Video Button
        ElevatedButton(
          onPressed: _startExport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Save as Video',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildExportingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Exporting Video...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please do not lock your device or switch apps.',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: _exportProgress,
          backgroundColor: AppTheme.surfaceVariant,
          color: AppTheme.primary,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        Text(
          '${(_exportProgress * 100).toInt()}%',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            _exportTimer?.cancel();
            setState(() => _isExporting = false);
          },
          child: const Text('Cancel Export',
              style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  Widget _buildCompletedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 54, color: Color(0xFF10B981)),
        const SizedBox(height: 12),
        const Text(
          'Export Successful!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.project.name}.mp4 is ready in your gallery.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
