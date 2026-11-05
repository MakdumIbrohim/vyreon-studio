import 'dart:async';
import 'dart:math';
import '../../services/audio_playback_service.dart';
import '../editor_controller_base.dart';

mixin EditorPlaybackMixin on EditorControllerBase {
  Timer? playbackTimer;
  DateTime? lastTickTime;

  @override
  void clampPlayhead() {
    final maxD = max(1000, project.totalDurationMs);
    if (playheadMs > maxD) {
      playheadMs = maxD;
    }
  }

  @override
  void syncAudio() {
    AudioPlaybackService.instance.syncPlayback(
      playheadMs: playheadMs,
      isPlaying: isPlaying,
      audioClips: project.clips,
      masterVolume: project.settings.masterVolume,
      isMasterMuted: project.settings.isMasterMuted,
      audioFadeInDuration: project.settings.audioFadeInDuration,
      audioFadeOutDuration: project.settings.audioFadeOutDuration,
      totalDurationMs: project.totalDurationMs,
    );
  }

  void seekTo(int ms) {
    final total = max(1000, project.totalDurationMs);
    playheadMs = ms.clamp(0, total);
    syncAudio();
    notifyListeners();
  }

  void setTimelineScale(double scale) {
    timelineScale = scale.clamp(20.0, 200.0);
    notifyListeners();
  }

  void togglePlay() {
    if (isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    if (isPlaying) return;
    final total = project.totalDurationMs;
    if (playheadMs >= total && total > 0) {
      playheadMs = 0;
    }
    isPlaying = true;
    lastTickTime = DateTime.now();
    syncAudio();

    playbackTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      final now = DateTime.now();
      final dt = now.difference(lastTickTime!).inMilliseconds;
      lastTickTime = now;

      double currentSpeedMultiplier = 1.0;
      for (final c in project.primaryClips) {
        if (playheadMs >= c.startMs && playheadMs < c.endMs) {
          final progress =
              c.durationMs > 0 ? (playheadMs - c.startMs) / c.durationMs : 0.0;
          currentSpeedMultiplier = c.getEffectiveSpeedAt(progress);
          break;
        }
      }

      playheadMs += (dt * currentSpeedMultiplier).round();
      final maxD = project.totalDurationMs;
      if (playheadMs >= maxD) {
        playheadMs = maxD;
        pause();
      }
      syncAudio();
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    if (!isPlaying) return;
    isPlaying = false;
    playbackTimer?.cancel();
    playbackTimer = null;
    syncAudio();
    notifyListeners();
  }

  void disposePlayback() {
    playbackTimer?.cancel();
    playbackTimer = null;
    AudioPlaybackService.instance.dispose();
  }
}
