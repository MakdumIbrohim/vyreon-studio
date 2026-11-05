import 'package:flutter/material.dart';
import '../../models/aspect_ratio.dart';
import '../../theme/app_theme.dart';

class AspectRatioPicker extends StatelessWidget {
  final ProjectAspectRatio selectedRatio;
  final ValueChanged<ProjectAspectRatio> onRatioSelected;

  const AspectRatioPicker({
    super.key,
    required this.selectedRatio,
    required this.onRatioSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ProjectAspectRatio.values.map((ratio) {
        final isSelected = selectedRatio == ratio;
        return InkWell(
          onTap: () => onRatioSelected(ratio),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 115,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ratio.icon,
                  size: 26,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
                const SizedBox(height: 6),
                Text(
                  ratio.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ratio.description,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
