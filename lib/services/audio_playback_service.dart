import 'dart:io';
import 'package:just_audio/just_audio.dart';
import '../models/timeline_clip.dart';

class AudioPlaybackService {
  static final AudioPlaybackService instance = AudioPlaybackService._();
  AudioPlaybackService._();

  AudioPlayer? _player;
  String? _currentLoadedPath;
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized && _player != null) return;
    try {
      _player = AudioPlayer();
      _isInitialized = true;
    } catch (_) {
      // Audio device unavailable or restricted
    }
  }

  Future<void> syncPlayback({
    required int playheadMs,
    required bool isPlaying,
    required List<TimelineClip> audioClips,
  }) async {
    await _ensureInitialized();
    final player = _player;
    if (player == null) return;

    if (!isPlaying) {
      try {
        if (player.playing) {
          await player.pause();
        }
      } catch (_) {}
      return;
    }

    // Find active audio clip at playhead
    TimelineClip? activeClip;
    for (final clip in audioClips) {
      if (clip.type == ClipType.audio &&
          playheadMs >= clip.startMs &&
          playheadMs < clip.endMs) {
        activeClip = clip;
        break;
      }
    }

    if (activeClip == null || activeClip.assetPath == null) {
      try {
        if (player.playing) {
          await player.pause();
        }
      } catch (_) {}
      return;
    }

    final path = activeClip.assetPath!;
    final file = File(path);
    if (!file.existsSync()) {
      try {
        if (player.playing) {
          await player.pause();
        }
      } catch (_) {}
      return;
    }

    final clipOffsetMs =
        (playheadMs - activeClip.startMs) + activeClip.sourceInMs;
    final targetDuration = Duration(milliseconds: clipOffsetMs);

    try {
      if (_currentLoadedPath != path) {
        _currentLoadedPath = path;
        await player.setFilePath(path);
      }

      final vol = activeClip.isMuted
          ? 0.0
          : (activeClip.volume.clamp(0.0, 1.0));
      await player.setVolume(vol);

      // Apply Voice Changer Pitch (semitones to pitch multiplier: 2^(semitones / 12))
      final semitones = activeClip.voiceChanger.pitchSemitones;
      final pitchMultiplier = semitones == 0
          ? 1.0
          : (1.0 * (semitones > 0 ? 1.0 + (semitones * 0.07) : 1.0 + (semitones * 0.05))).clamp(0.5, 2.0);
      try {
        await player.setPitch(pitchMultiplier);
      } catch (_) {}

      final currentPos = player.position;
      final diffMs = (currentPos.inMilliseconds - clipOffsetMs).abs();

      if (diffMs > 300) {
        await player.seek(targetDuration);
      }

      if (!player.playing) {
        player.play();
      }
    } catch (_) {
      // Graceful fallback if audio format is unsupported
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _player?.dispose();
      _player = null;
      _isInitialized = false;
      _currentLoadedPath = null;
    } catch (_) {}
  }
}
