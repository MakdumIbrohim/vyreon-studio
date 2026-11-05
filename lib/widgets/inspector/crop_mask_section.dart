import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';
import 'inspector_slider.dart';

class CropMaskSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const CropMaskSection({
    super.key,
    required this.controller,
    required this.clip,
  });

  @override
  Widget build(BuildContext context) {
    final mask = clip.cropMask;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.crop, size: 16, color: Colors.tealAccent),
                  SizedBox(width: 6),
                  Text(
                    'Cropping & Shape Mask',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: mask.isMaskEnabled,
                activeTrackColor: Colors.tealAccent,
                onChanged: (val) {
                  controller.updateClip(
                    clip.copyWith(cropMask: mask.copyWith(isMaskEnabled: val)),
                  );
                },
              ),
            ],
          ),
          if (mask.isMaskEnabled) ...[
            const SizedBox(height: 6),
            const Text(
              'MASK SHAPE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: MaskShape.values.map((shape) {
                  final isSel = mask.maskShape == shape;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        shape.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSel ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: Colors.teal.shade700,
                      backgroundColor: AppTheme.surfaceVariant,
                      onSelected: (_) => controller.updateClip(
                        clip.copyWith(
                          cropMask: mask.copyWith(maskShape: shape),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 12, color: AppTheme.divider),
          ],

          // Crop Margins
          InspectorSlider(
            label: 'Crop Horizontal',
            value: mask.cropLeft * 100,
            min: 0.0,
            max: 40.0,
            onChanged: (val) {
              controller.updateClip(
                clip.copyWith(
                  cropMask: mask.copyWith(
                    cropLeft: val / 100.0,
                    cropRight: val / 100.0,
                  ),
                ),
              );
            },
          ),
          InspectorSlider(
            label: 'Crop Vertical',
            value: mask.cropTop * 100,
            min: 0.0,
            max: 40.0,
            onChanged: (val) {
              controller.updateClip(
                clip.copyWith(
                  cropMask: mask.copyWith(
                    cropTop: val / 100.0,
                    cropBottom: val / 100.0,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
