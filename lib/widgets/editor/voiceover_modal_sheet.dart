import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../../models/timeline_clip.dart';
import '../../services/audio_recording_service.dart';
import '../../services/audio_waveform_service.dart';
import '../../state/editor_controller.dart';
import '../../theme/app_theme.dart';

class VoiceoverModalSheet extends StatefulWidget {
  final EditorController controller;

  const VoiceoverModalSheet({super.key, required this.controller});

  static void show(BuildContext context, EditorController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => VoiceoverModalSheet(controller: controller),
    );
  }

  @override
  State<VoiceoverModalSheet> createState() => _VoiceoverModalSheetState();
}

class _VoiceoverModalSheetState extends State<VoiceoverModalSheet> {
  bool _isRecording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  StreamSubscription<Amplitude>? _ampSub;
  double _currentAmplitude = 0.0;
  String? _errorMessage;

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    if (_isRecording) {
      AudioRecordingService.instance.stopRecording();
    }
    super.dispose();
  }

  String _formatTimer(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = ((d.inMilliseconds % 1000) ~/ 100).toString();
    return '$m:$s.$ms';
  }

  Future<void> _startRecording() async {
    setState(() => _errorMessage = null);
    try {
      await AudioRecordingService.instance.startRecording();
      _ampSub = AudioRecordingService.instance
          .getAmplitudeStream()
          ?.listen((amp) {
        if (!mounted) return;
        // amp.current ranges roughly from -60 dB to 0 dB
        final norm = ((amp.current + 60.0) / 60.0).clamp(0.05, 1.0);
        setState(() => _currentAmplitude = norm);
      });

      _elapsed = Duration.zero;
      _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        if (!mounted) return;
        setState(() {
          _elapsed = Duration(milliseconds: t.tick * 100);
        });
      });

      setState(() => _isRecording = true);
    } catch (e) {
      setState(() {
        _isRecording = false;
        _errorMessage = 'Microphone access failed: $e';
      });
    }
  }

  Future<void> _stopAndInsert() async {
    _timer?.cancel();
    _timer = null;
    await _ampSub?.cancel();
    _ampSub = null;

    final recordedPath =
        await AudioRecordingService.instance.stopRecording();
    if (!mounted) return;

    final durationMs = max(500, _elapsed.inMilliseconds);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (recordedPath != null) {
      final voiceClip = TimelineClip(
        id: 'voice_$now',
        name: 'Voiceover ${DateTime.now().minute}:${DateTime.now().second}',
        type: ClipType.audio,
        startMs: widget.controller.playheadMs,
        durationMs: durationMs,
        sourceDurationMs: durationMs,
        assetPath: recordedPath,
        colorValue: 0xFFF59E0B, // Amber
        isPrimary: false,
        trackIndex: 3,
      );

      widget.controller.addSecondaryClip(voiceClip);

      // Populate waveform samples in background
      AudioWaveformService()
          .getWaveformSamples(
        filePath: recordedPath,
        clipId: voiceClip.id,
        durationMs: durationMs,
      )
          .then((samples) {
        final idx = widget.controller.project.clips
            .indexWhere((c) => c.id == voiceClip.id);
        if (idx >= 0) {
          final updated = widget.controller.project.clips[idx]
              .copyWith(waveformSamples: samples);
          widget.controller.updateClip(updated);
        }
      });
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                size: 24,
                color: _isRecording ? Colors.redAccent : AppTheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Voiceover Recorder',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style:
                    const TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ),

          // Timer & VU meter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRecording)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      _formatTimer(_elapsed),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color:
                            _isRecording ? Colors.redAccent : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Real-time Audio VU Level Meter
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _isRecording ? _currentAmplitude : 0.0,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _currentAmplitude > 0.8
                          ? Colors.redAccent
                          : (_currentAmplitude > 0.5
                              ? Colors.amberAccent
                              : const Color(0xFF10B981)),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isRecording
                    ? 'Recording microphone audio...'
                    : 'Inserts voice clip at playhead (${(widget.controller.playheadMs / 1000).toStringAsFixed(1)}s)',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Button
          if (!_isRecording)
            ElevatedButton.icon(
              onPressed: _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.fiber_manual_record, size: 20),
              label: const Text(
                'Start Recording',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _stopAndInsert,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.stop, size: 20),
              label: const Text(
                'Stop & Insert to Timeline',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
