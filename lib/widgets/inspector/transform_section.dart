import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import 'inspector_slider.dart';

class TransformSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const TransformSection({
    super.key,
    required this.controller,
    required this.clip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InspectorSlider(
          label: 'Scale',
          value: clip.scale,
          min: 0.2,
          max: 3.0,
          onChanged: (val) => controller.updateClip(clip.copyWith(scale: val)),
        ),
        InspectorSlider(
          label: 'Rotation',
          value: clip.rotation,
          min: -180.0,
          max: 180.0,
          onChanged: (val) =>
              controller.updateClip(clip.copyWith(rotation: val)),
        ),
        if (!clip.isPrimary) ...[
          InspectorSlider(
            label: 'Position X',
            value: clip.offsetX,
            min: -1.0,
            max: 1.0,
            onChanged: (val) =>
                controller.updateClip(clip.copyWith(offsetX: val)),
          ),
          InspectorSlider(
            label: 'Position Y',
            value: clip.offsetY,
            min: -1.0,
            max: 1.0,
            onChanged: (val) =>
                controller.updateClip(clip.copyWith(offsetY: val)),
          ),
        ],
      ],
    );
  }
}
