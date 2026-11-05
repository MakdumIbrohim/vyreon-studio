import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../services/video_render_service.dart';
import '../../theme/app_theme.dart';

class ExportConfigView extends StatelessWidget {
  final Project project;
  final String selectedResolution;
  final int selectedFps;
  final double bitrateMbps;
  final double estimatedFileSizeMb;
  final String? exportError;
  final List<String> resolutions;
  final List<int> frameRates;
  final ValueChanged<String> onSelectResolution;
  final ValueChanged<int> onSelectFps;
  final ValueChanged<double> onChangeBitrate;
  final VoidCallback onStartExport;

  const ExportConfigView({
    super.key,
    required this.project,
    required this.selectedResolution,
    required this.selectedFps,
    required this.bitrateMbps,
    required this.estimatedFileSizeMb,
    this.exportError,
    required this.resolutions,
    required this.frameRates,
    required this.onSelectResolution,
    required this.onSelectFps,
    required this.onChangeBitrate,
    required this.onStartExport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const Text(
          'RESOLUTION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: resolutions.map((res) {
            final isSel = selectedResolution == res;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      res,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceVariant,
                  onSelected: (_) => onSelectResolution(res),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        const Text(
          'FRAME RATE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: frameRates.map((fps) {
            final isSel = selectedFps == fps;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      '$fps fps',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceVariant,
                  onSelected: (_) => onSelectFps(fps),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'QUALITY / BITRATE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            Text(
              '${bitrateMbps.toStringAsFixed(1)} Mbps',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        Slider(
          value: bitrateMbps,
          min: 2.0,
          max: 30.0,
          onChanged: onChangeBitrate,
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimated File Size:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                'About ${estimatedFileSizeMb.toStringAsFixed(1)} MB',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_outlined,
                      size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project.settings.customExportDirectory ??
                          '~/Videos/VyreonStudio',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.movie_creation_outlined,
                      size: 15, color: Colors.cyanAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      VideoRenderService.formatOutputFilename(
                        projectName: project.name,
                        resolution: selectedResolution,
                        fps: selectedFps,
                      ),
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (exportError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Text(
              exportError!,
              style: const TextStyle(fontSize: 11, color: Colors.redAccent),
            ),
          ),
        ],
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: onStartExport,
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
}
