import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../theme/app_theme.dart';

class TransitionSelectorDialog extends StatefulWidget {
  final TimelineClip clip;

  const TransitionSelectorDialog({super.key, required this.clip});

  @override
  State<TransitionSelectorDialog> createState() =>
      _TransitionSelectorDialogState();
}

class _TransitionSelectorDialogState extends State<TransitionSelectorDialog> {
  late TransitionType _selected;
  late double _durationSec;

  @override
  void initState() {
    super.initState();
    _selected = widget.clip.transition;
    _durationSec = widget.clip.transitionDurationMs / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
          SizedBox(width: 8),
          Text('Clip Transition', style: TextStyle(fontSize: 16)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Transition Effect:',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TransitionType.values.map((t) {
              final isSel = _selected == t;
              return ChoiceChip(
                avatar: Icon(
                  t.icon,
                  size: 16,
                  color: isSel ? Colors.white : AppTheme.textSecondary,
                ),
                label: Text(t.label),
                selected: isSel,
                selectedColor: AppTheme.primary,
                backgroundColor: AppTheme.surfaceVariant,
                onSelected: (_) => setState(() => _selected = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Duration:',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              Text('${_durationSec.toStringAsFixed(1)}s',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _durationSec,
            min: 0.5,
            max: 3.0,
            onChanged: (val) => setState(() => _durationSec = val),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          onPressed: () {
            final newClip = widget.clip.copyWith(
              transition: _selected,
              transitionDurationMs: (_durationSec * 1000).round(),
            );
            Navigator.of(context).pop(newClip);
          },
          child: const Text('Apply', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
