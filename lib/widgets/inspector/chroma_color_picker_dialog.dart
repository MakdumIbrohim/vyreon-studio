import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ChromaColorPickerDialog extends StatefulWidget {
  final int initialColor;

  const ChromaColorPickerDialog({super.key, required this.initialColor});

  static Future<int?> show(BuildContext context, int initialColor) {
    return showDialog<int>(
      context: context,
      builder: (_) => ChromaColorPickerDialog(initialColor: initialColor),
    );
  }

  @override
  State<ChromaColorPickerDialog> createState() =>
      _ChromaColorPickerDialogState();
}

class _ChromaColorPickerDialogState extends State<ChromaColorPickerDialog> {
  late int _r;
  late int _g;
  late int _b;
  late TextEditingController _hexController;

  static const List<int> _quickPresets = [
    0xFF00FF00, // Pure Green
    0xFF00B140, // Standard Chroma Key Green
    0xFF04D9FF, // Neon Cyan
    0xFF0000FF, // Pure Blue
    0xFF1F45FC, // Blue Screen
    0xFFFF00FF, // Magenta Screen
    0xFF00FF7F, // Spring Green
    0xFF7FFF00, // Chartreuse
  ];

  @override
  void initState() {
    super.initState();
    _r = (widget.initialColor >> 16) & 0xFF;
    _g = (widget.initialColor >> 8) & 0xFF;
    _b = widget.initialColor & 0xFF;
    _hexController = TextEditingController(text: _formatHex());
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _formatHex() {
    return '${_r.toRadixString(16).padLeft(2, '0')}${_g.toRadixString(16).padLeft(2, '0')}${_b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  int get _currentColor => (0xFF << 24) | (_r << 16) | (_g << 8) | _b;

  void _updateFromSliders() {
    _hexController.text = _formatHex();
    setState(() {});
  }

  void _updateFromHex(String val) {
    final cleaned = val.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      final parsed = int.tryParse(cleaned, radix: 16);
      if (parsed != null) {
        setState(() {
          _r = (parsed >> 16) & 0xFF;
          _g = (parsed >> 8) & 0xFF;
          _b = parsed & 0xFF;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Row(
                children: [
                  const Icon(Icons.palette, size: 22, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Chroma Key Color Picker',
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

              // Color Preview & Hex code
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Color(_currentColor),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Color(_currentColor).withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HEX COLOR CODE',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _hexController,
                          maxLength: 6,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            prefixText: '# ',
                            prefixStyle: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold),
                            counterText: '',
                            filled: true,
                            fillColor: AppTheme.surfaceVariant,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: _updateFromHex,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // RGB Sliders
              _buildSliderRow('R', _r, Colors.redAccent, (val) {
                _r = val.toInt();
                _updateFromSliders();
              }),
              _buildSliderRow('G', _g, Colors.greenAccent, (val) {
                _g = val.toInt();
                _updateFromSliders();
              }),
              _buildSliderRow('B', _b, Colors.blueAccent, (val) {
                _b = val.toInt();
                _updateFromSliders();
              }),

              const SizedBox(height: 12),

              // Quick presets
              const Text(
                'QUICK PRESETS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickPresets.map((presetColor) {
                  final isSelected = _currentColor == presetColor;
                  return InkWell(
                    onTap: () {
                      _r = (presetColor >> 16) & 0xFF;
                      _g = (presetColor >> 8) & 0xFF;
                      _b = presetColor & 0xFF;
                      _updateFromSliders();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(presetColor),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.black45,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_currentColor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply Color'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow(
    String label,
    int value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}
