import 'package:flutter/material.dart';
import '../../models/timeline_clip.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class AudioFxSection extends StatelessWidget {
  final EditorController controller;
  final TimelineClip clip;

  const AudioFxSection({
    super.key,
    required this.controller,
    required this.clip,
  });

  @override
  Widget build(BuildContext context) {
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
          // EQ Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Equalizer (EQ Preset)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                clip.eqPreset.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 5-band visual graphic
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBandBar('100Hz', clip.eqPreset.bandGains[0]),
                _buildBandBar('300Hz', clip.eqPreset.bandGains[1]),
                _buildBandBar('1kHz', clip.eqPreset.bandGains[2]),
                _buildBandBar('3kHz', clip.eqPreset.bandGains[3]),
                _buildBandBar('10kHz', clip.eqPreset.bandGains[4]),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // EQ Preset Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AudioEqPreset.values.map((preset) {
                final isSel = clip.eqPreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      preset.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surfaceVariant,
                    onSelected: (_) => controller
                        .updateClip(clip.copyWith(eqPreset: preset)),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 18, color: AppTheme.divider),

          // Voice Changer Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Voice Changer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (clip.voiceChanger != VoiceChangerPreset.none)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${clip.voiceChanger.pitchSemitones > 0 ? "+" : ""}${clip.voiceChanger.pitchSemitones} st',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Colors.amber,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Voice Changer Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: VoiceChangerPreset.values.map((vc) {
                final isSel = clip.voiceChanger == vc;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      vc.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: Colors.deepPurpleAccent,
                    backgroundColor: AppTheme.surfaceVariant,
                    onSelected: (_) => controller
                        .updateClip(clip.copyWith(voiceChanger: vc)),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 18, color: AppTheme.divider),

          // Reverb & Acoustic Room Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reverb (Acoustic Space)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                clip.reverbPreset.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightGreenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Reverb Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AudioReverbPreset.values.map((rv) {
                final isSel = clip.reverbPreset == rv;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      rv.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSel ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: Colors.teal.shade700,
                    backgroundColor: AppTheme.surfaceVariant,
                    onSelected: (_) => controller
                        .updateClip(clip.copyWith(reverbPreset: rv)),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 18, color: AppTheme.divider),

          // Audio Beat Detection & Markers Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rhythm & Beat Markers',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${clip.beatMarkers.length} Beats',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Colors.amberAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.detectBeatsForClip(clip.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceVariant,
                    foregroundColor: Colors.amberAccent,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Colors.amberAccent, width: 0.8),
                    ),
                  ),
                  icon: const Icon(Icons.graphic_eq, size: 16),
                  label: const Text(
                    'Auto-Detect Beats',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                tooltip: 'Add/Remove Beat Marker at Playhead',
                icon: const Icon(Icons.pin_drop, size: 16, color: Colors.white),
                onPressed: () => controller.toggleBeatMarkerAtPlayhead(clip.id),
              ),
              if (clip.beatMarkers.isNotEmpty) ...[
                const SizedBox(width: 4),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  tooltip: 'Clear All Beat Markers',
                  icon: const Icon(Icons.delete_sweep,
                      size: 16, color: Colors.redAccent),
                  onPressed: () =>
                      controller.updateClip(clip.copyWith(beatMarkers: [])),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Timeline playhead snaps automatically to rhythm beat markers during scrubbing.',
            style: TextStyle(fontSize: 9, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBandBar(String freq, int gainDb) {
    // gainDb ranges from -12 to +12
    final norm = ((gainDb + 12) / 24).clamp(0.1, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 18 * norm,
          decoration: BoxDecoration(
            color: gainDb >= 0 ? AppTheme.primary : Colors.cyanAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          freq,
          style: const TextStyle(fontSize: 8, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
