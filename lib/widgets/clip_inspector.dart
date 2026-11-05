import 'package:flutter/material.dart';
import '../models/timeline_clip.dart';
import '../state/editor_controller.dart';
import '../theme/app_theme.dart';
import 'inspector/audio_fx_section.dart';
import 'inspector/audio_speed_section.dart';
import 'inspector/chroma_key_section.dart';
import 'inspector/clip_management_section.dart';
import 'inspector/color_filter_section.dart';
import 'inspector/crop_mask_section.dart';
import 'inspector/inspector_slider.dart';
import 'inspector/keyframe_section.dart';
import 'inspector/layer_animation_section.dart';
import 'inspector/layer_order_section.dart';
import 'inspector/pan_zoom_section.dart';
import 'inspector/pip_section.dart';
import 'inspector/text_style_section.dart';
import 'inspector/transform_section.dart';
import 'inspector/trim_split_toolbar.dart';
import 'inspector/volume_envelope_section.dart';

class ClipInspector extends StatefulWidget {
  final EditorController controller;
  final TimelineClip clip;

  const ClipInspector({
    super.key,
    required this.controller,
    required this.clip,
  });

  @override
  State<ClipInspector> createState() => _ClipInspectorState();
}

class _ClipInspectorState extends State<ClipInspector> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController =
        TextEditingController(text: widget.clip.textContent);
  }

  @override
  void didUpdateWidget(covariant ClipInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip.id != widget.clip.id ||
        oldWidget.clip.textContent != widget.clip.textContent) {
      _textEditingController.text = widget.clip.textContent;
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppTheme.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final controller = widget.controller;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          left: BorderSide(color: AppTheme.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Inspector Header (Title & Deselect)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppTheme.cardColor,
            child: Row(
              children: [
                Icon(clip.type.icon, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    clip.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  color: AppTheme.textSecondary,
                  tooltip: 'Done / Deselect',
                  onPressed: () => controller.selectClip(null),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.divider),

          // Scrollable tools list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                // Quick Actions: Split & Trim
                _buildSectionHeader('TRIM & SPLIT'),
                TrimSplitToolbar(controller: controller, clip: clip),

                const SizedBox(height: 14),

                // Text Editing section (if text clip)
                if (clip.type == ClipType.text) ...[
                  _buildSectionHeader('TEXT CONTENT'),
                  TextField(
                    controller: _textEditingController,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Enter text...',
                    ),
                    onChanged: (val) {
                      controller.updateClip(clip.copyWith(textContent: val));
                    },
                  ),
                  const SizedBox(height: 8),
                  InspectorSlider(
                    label: 'Font Size',
                    value: clip.fontSize,
                    min: 12.0,
                    max: 72.0,
                    onChanged: (val) =>
                        controller.updateClip(clip.copyWith(fontSize: val)),
                  ),
                  const SizedBox(height: 10),
                  TextStyleSection(controller: controller, clip: clip),
                  const SizedBox(height: 14),
                ],

                // Transform & Positioning
                _buildSectionHeader('TRANSFORM'),
                TransformSection(controller: controller, clip: clip),

                const SizedBox(height: 14),

                // Keyframe Animation
                _buildSectionHeader('KEYFRAME ANIMATION'),
                KeyframeSection(controller: controller, clip: clip),

                const SizedBox(height: 14),

                // Color Filters & Vignette
                _buildSectionHeader('COLOR FILTER & VIGNETTE'),
                ColorFilterSection(controller: controller, clip: clip),

                const SizedBox(height: 14),

                // Chroma Key (Green Screen)
                if (!clip.isPrimary) ...[
                  _buildSectionHeader('CHROMA KEY'),
                  ChromaKeySection(controller: controller, clip: clip),
                  const SizedBox(height: 14),
                ],

                // Opacity & Blending
                _buildSectionHeader('OPACITY & BLEND'),
                InspectorSlider(
                  label: 'Alpha',
                  value: clip.opacity * 100,
                  min: 0.0,
                  max: 100.0,
                  onChanged: (val) => controller
                      .updateClip(clip.copyWith(opacity: val / 100.0)),
                ),

                const SizedBox(height: 14),

                // Audio Volume, Mute & Playback Speed
                _buildSectionHeader('AUDIO & SPEED'),
                AudioSpeedSection(controller: controller, clip: clip),

                const SizedBox(height: 14),

                // Audio Equalizer, Voice Changer, Reverb, Volume Envelope & Ducking
                if (clip.type == ClipType.audio || clip.type == ClipType.video) ...[
                  _buildSectionHeader('EQ, VOICE CHANGER & REVERB'),
                  AudioFxSection(controller: controller, clip: clip),
                  const SizedBox(height: 14),
                  _buildSectionHeader('VOLUME ENVELOPE & DUCKING'),
                  VolumeEnvelopeSection(controller: controller, clip: clip),
                  const SizedBox(height: 14),
                ],

                // Pan & Zoom (Ken Burns) and Cropping
                if (clip.type != ClipType.audio) ...[
                  _buildSectionHeader('PAN & ZOOM'),
                  PanZoomSection(controller: controller, clip: clip),
                  const SizedBox(height: 14),
                  _buildSectionHeader('CROPPING & SHAPE MASK'),
                  CropMaskSection(controller: controller, clip: clip),
                  const SizedBox(height: 14),
                ],

                // Picture-in-Picture, Z-Index & Layer Animations
                if (!clip.isPrimary && clip.type != ClipType.audio) ...[
                  _buildSectionHeader('SPLIT SCREEN / PIP'),
                  PipSection(controller: controller, clip: clip),
                  const SizedBox(height: 14),
                  _buildSectionHeader('LAYER ORDER (Z-INDEX)'),
                  LayerOrderSection(controller: controller, clip: clip),
                  const SizedBox(height: 14),
                  _buildSectionHeader('LAYER ANIMATIONS'),
                  LayerAnimationSection(controller: controller, clip: clip),
                  const SizedBox(height: 14),
                ],

                // Duplicate, As Layer, Reverse & Extract Audio controls
                _buildSectionHeader('CLIP MANAGEMENT'),
                ClipManagementSection(controller: controller, clip: clip),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
