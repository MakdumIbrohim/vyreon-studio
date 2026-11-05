import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ExportProgressView extends StatelessWidget {
  final double progress;
  final VoidCallback onCancel;

  const ExportProgressView({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
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
          value: progress,
          backgroundColor: AppTheme.surfaceVariant,
          color: AppTheme.primary,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: onCancel,
          child: const Text(
            'Cancel Export',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }
}
