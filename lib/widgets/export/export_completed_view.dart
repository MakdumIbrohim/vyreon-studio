import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ExportCompletedView extends StatelessWidget {
  final String resolution;
  final int fileSize;
  final String outputPath;
  final VoidCallback onDone;

  const ExportCompletedView({
    super.key,
    required this.resolution,
    required this.fileSize,
    required this.outputPath,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final sizeKb = (fileSize / 1024).round();
    final sizeFormatted = sizeKb > 1024
        ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
        : '$sizeKb KB';

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
          'Rendered at $resolution • $sizeFormatted',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SelectableText(
            outputPath,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: AppTheme.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onDone,
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
