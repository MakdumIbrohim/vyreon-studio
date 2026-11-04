import 'package:flutter/material.dart';
import '../models/timeline_clip.dart';
import '../state/editor_controller.dart';
import '../theme/app_theme.dart';

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
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.cut,
                        label: 'Split',
                        onTap: () => controller.splitClipAtPlayhead(clip.id),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.keyboard_tab,
                        label: 'Trim L',
                        onTap: () => controller.trimClipLeft(clip.id),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.east,
                        label: 'Trim R',
                        onTap: () => controller.trimClipRight(clip.id),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        color: Colors.redAccent,
                        onTap: () => controller.deleteClip(clip.id),
                      ),
                    ),
                  ],
                ),

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
                  _buildSlider(
                    label: 'Font Size',
                    value: clip.fontSize,
                    min: 12.0,
                    max: 72.0,
                    onChanged: (val) =>
                        controller.updateClip(clip.copyWith(fontSize: val)),
                  ),
                  const SizedBox(height: 14),
                ],

                // Transform & Positioning
                _buildSectionHeader('TRANSFORM'),
                _buildSlider(
                  label: 'Scale',
                  value: clip.scale,
                  min: 0.2,
                  max: 3.0,
                  onChanged: (val) =>
                      controller.updateClip(clip.copyWith(scale: val)),
                ),
                _buildSlider(
                  label: 'Rotation',
                  value: clip.rotation,
                  min: -180.0,
                  max: 180.0,
                  onChanged: (val) =>
                      controller.updateClip(clip.copyWith(rotation: val)),
                ),
                if (!clip.isPrimary) ...[
                  _buildSlider(
                    label: 'Position X',
                    value: clip.offsetX,
                    min: -1.0,
                    max: 1.0,
                    onChanged: (val) =>
                        controller.updateClip(clip.copyWith(offsetX: val)),
                  ),
                  _buildSlider(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, size: 18),
                        tooltip: 'Previous Keyframe',
                        onPressed: clip.keyframes.isEmpty
                            ? null
                            : () => controller.jumpToPreviousKeyframe(clip.id),
                      ),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              controller.toggleKeyframeAtPlayhead(clip.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.hasKeyframeNearPlayhead(clip)
                                ? Colors.redAccent
                                : AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          icon: Icon(
                            controller.hasKeyframeNearPlayhead(clip)
                                ? Icons.remove
                                : Icons.add,
                            size: 16,
                          ),
                          label: Text(
                            controller.hasKeyframeNearPlayhead(clip)
                                ? 'Remove'
                                : 'Add Keyframe',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 18),
                        tooltip: 'Next Keyframe',
                        onPressed: clip.keyframes.isEmpty
                            ? null
                            : () => controller.jumpToNextKeyframe(clip.id),
                      ),
                    ],
                  ),
                ),
                if (clip.keyframes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      '${clip.keyframes.length} keyframes active',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ),

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

                // Chroma Key (Green Screen)
                if (!clip.isPrimary) ...[
                  _buildSectionHeader('CHROMA KEY'),
                  Container(
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
                            const Text(
                              'Enable Chroma Key',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary),
                            ),
                            Switch(
                              value: clip.isChromaKeyEnabled,
                              activeTrackColor: AppTheme.primary,
                              onChanged: (val) => controller.updateClip(
                                  clip.copyWith(isChromaKeyEnabled: val)),
                            ),
                          ],
                        ),
                        if (clip.isChromaKeyEnabled) ...[
                          const SizedBox(height: 8),
                          const Text('Key Color:',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.textMuted)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildKeyColorChip(
                                  controller, clip, 'Green', 0xFF00FF00),
                              const SizedBox(width: 6),
                              _buildKeyColorChip(
                                  controller, clip, 'Blue', 0xFF0000FF),
                              const SizedBox(width: 6),
                              _buildKeyColorChip(
                                  controller, clip, 'Cyan', 0xFF00FFFF),
                              const SizedBox(width: 6),
                              _buildKeyColorChip(
                                  controller, clip, 'Magenta', 0xFFFF00FF),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildSlider(
                            label: 'Threshold (Similarity)',
                            value: clip.chromaThreshold * 100,
                            min: 5.0,
                            max: 90.0,
                            onChanged: (val) => controller.updateClip(
                                clip.copyWith(chromaThreshold: val / 100.0)),
                          ),
                          _buildSlider(
                            label: 'Detail (Smoothness)',
                            value: clip.chromaSmoothness * 100,
                            min: 0.0,
                            max: 50.0,
                            onChanged: (val) => controller.updateClip(
                                clip.copyWith(chromaSmoothness: val / 100.0)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Show B&W Mask',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary)),
                              Switch(
                                value: clip.chromaShowMask,
                                activeTrackColor: Colors.amber,
                                onChanged: (val) => controller.updateClip(
                                    clip.copyWith(chromaShowMask: val)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Opacity & Blending
                _buildSectionHeader('OPACITY & BLEND'),
                _buildSlider(
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
                _buildSlider(
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

                const SizedBox(height: 18),

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

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppTheme.textPrimary),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildKeyColorChip(
    EditorController controller,
    TimelineClip clip,
    String label,
    int colorVal,
  ) {
    final isSel = clip.chromaKeyColor == colorVal;
    return InkWell(
      onTap: () => controller.updateClip(clip.copyWith(chromaKeyColor: colorVal)),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: Color(colorVal).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSel ? Colors.white : Color(colorVal).withValues(alpha: 0.5),
            width: isSel ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(colorVal),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
