import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ProjectDurationOptions extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final double photoDuration;
  final ValueChanged<double> onPhotoDurationChanged;
  final double transitionDuration;
  final ValueChanged<double> onTransitionDurationChanged;

  const ProjectDurationOptions({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.photoDuration,
    required this.onPhotoDurationChanged,
    required this.transitionDuration,
    required this.onTransitionDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Row(
            children: [
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 20,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              const Text(
                'Advanced Settings',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Default Photo Duration',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                '${photoDuration.toStringAsFixed(1)}s',
                style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
              ),
            ],
          ),
          Slider(
            value: photoDuration,
            min: 1.0,
            max: 15.0,
            onChanged: onPhotoDurationChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Default Transition Duration',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                '${transitionDuration.toStringAsFixed(1)}s',
                style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
              ),
            ],
          ),
          Slider(
            value: transitionDuration,
            min: 0.5,
            max: 5.0,
            onChanged: onTransitionDurationChanged,
          ),
        ],
      ],
    );
  }
}
