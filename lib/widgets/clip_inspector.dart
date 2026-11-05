import 'package:flutter/material.dart';
import '../models/timeline_clip.dart';
import '../state/editor_controller.dart';
import '../theme/app_theme.dart';
import 'inspector/audio_fx_section.dart';
import 'inspector/chroma_key_section.dart';
import 'inspector/crop_mask_section.dart';
import 'inspector/inspector_slider.dart';
import 'inspector/keyframe_section.dart';
import 'inspector/layer_animation_section.dart';
import 'inspector/layer_order_section.dart';
import 'inspector/pan_zoom_section.dart';
import 'inspector/pip_section.dart';
import 'inspector/speed_ramp_section.dart';
import 'inspector/text_style_section.dart';
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: AppTheme.surfaceVariant,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color ?? AppTheme.textPrimary),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppTheme.textSecondary,
                ),
              ),
            ],
          ),
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
                InspectorSlider(
                  label: 'Scale',
                  value: clip.scale,
                  min: 0.2,
                  max: 3.0,
                  onChanged: (val) =>
                      controller.updateClip(clip.copyWith(scale: val)),
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

                const SizedBox(height: 14),

                // Keyframe Animation
                _buildSectionHeader('KEYFRAME ANIMATION'),
                KeyframeSection(controller: controller, clip: clip),

                const SizedBox(height: 14),

                // Color Filters
                _buildSectionHeader('COLOR FILTER'),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ColorFilterPreset.values.map((preset) {
                      final isSelected = clip.filter == preset;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            preset.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.primary,
                          backgroundColor: AppTheme.surfaceVariant,
                          onSelected: (_) => controller
                              .updateClip(clip.copyWith(filter: preset)),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 14),

                // Vignette Effect
                _buildSectionHeader('VIGNETTE EFFECT'),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cinematic Vignette',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Switch(
                            value: clip.isVignetteEnabled,
                            activeTrackColor: AppTheme.primary,
                            onChanged: (val) => controller.updateClip(
                              clip.copyWith(isVignetteEnabled: val),
                            ),
                          ),
                        ],
                      ),
                      if (clip.isVignetteEnabled) ...[
                        const SizedBox(height: 6),
                        InspectorSlider(
                          label: 'Intensity',
                          value: clip.vignetteIntensity * 100,
                          min: 10.0,
                          max: 100.0,
                          onChanged: (val) => controller.updateClip(
                            clip.copyWith(vignetteIntensity: val / 100.0),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

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

                // Audio & Speed
                _buildSectionHeader('AUDIO & SPEED'),
                InspectorSlider(
                  label: 'Volume',
                  value: clip.volume * 100,
                  min: 0.0,
                  max: 200.0,
                  onChanged: (val) => controller
                      .updateClip(clip.copyWith(volume: val / 100.0)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mute Audio',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Switch(
                      value: clip.isMuted,
                      activeTrackColor: AppTheme.primary,
                      onChanged: (val) =>
                          controller.updateClip(clip.copyWith(isMuted: val)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Playback Speed',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [0.25, 0.5, 1.0, 1.5, 2.0, 4.0].map((s) {
                    final isSel = (clip.speed - s).abs() < 0.05;
                    return InkWell(
                      onTap: () =>
                          controller.updateClip(clip.copyWith(speed: s)),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppTheme.primary
                              : AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${s}x',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 10),
                SpeedRampSection(controller: controller, clip: clip),

                const SizedBox(height: 14),

                // Audio Equalizer & Voice Changer
                if (clip.type == ClipType.audio || clip.type == ClipType.video) ...[
                  _buildSectionHeader('EQ & VOICE CHANGER'),
                  AudioFxSection(controller: controller, clip: clip),
                  const SizedBox(height: 14),
                  _buildSectionHeader('VOLUME ENVELOPE & DUCKING'),
                  VolumeEnvelopeSection(controller: controller, clip: clip),
                  const SizedBox(height: 14),
                ],

                // Pan & Zoom (Ken Burns)
                if (clip.type != ClipType.audio) ...[
                  _buildSectionHeader('PAN & ZOOM'),
                  PanZoomSection(controller: controller, clip: clip),
                  const SizedBox(height: 14),
                  _buildSectionHeader('CROPPING & SHAPE MASK'),
                  CropMaskSection(controller: controller, clip: clip),
                  const SizedBox(height: 14),
                ],

                // Picture-in-Picture & Split Screen Presets
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

                // Duplicate & Layer controls
                _buildSectionHeader('CLIP MANAGEMENT'),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.copy,
                        label: 'Duplicate',
                        onTap: () => controller.duplicateClip(clip.id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.layers,
                        label: 'As Layer',
                        onTap: () => controller.duplicateAsLayer(clip.id),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
