import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/timeline_clip.dart';
import '../services/audio_extraction_service.dart';
import '../services/audio_playback_service.dart';
import '../services/audio_waveform_service.dart';
import '../services/project_storage_service.dart';

class EditorController extends ChangeNotifier {
  Project _project;
  int _playheadMs = 0;
  bool _isPlaying = false;
  String? _selectedClipId;
  double _timelineScale = 60.0; // pixels per second
  Timer? _playbackTimer;
  DateTime? _lastTickTime;

  // Undo / Redo history
  final List<Project> _undoStack = [];
  final List<Project> _redoStack = [];
  static const int _maxHistory = 30;

  EditorController(this._project);

  Project get project => _project;
  int get playheadMs => _playheadMs;
  bool get isPlaying => _isPlaying;
  String? get selectedClipId => _selectedClipId;
  double get timelineScale => _timelineScale;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  TimelineClip? get selectedClip {
    if (_selectedClipId == null) return null;
    for (final c in _project.clips) {
      if (c.id == _selectedClipId) return c;
    }
    return null;
  }

  void _pushUndo() {
    _undoStack.add(_project);
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(_project);
    _project = _undoStack.removeLast();
    _clampPlayhead();
    notifyListeners();
    _autoSave();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(_project);
    _project = _redoStack.removeLast();
    _clampPlayhead();
    notifyListeners();
    _autoSave();
  }

  void _clampPlayhead() {
    final maxD = max(1000, _project.totalDurationMs);
    if (_playheadMs > maxD) {
      _playheadMs = maxD;
    }
  }

  void _syncAudio() {
    AudioPlaybackService.instance.syncPlayback(
      playheadMs: _playheadMs,
      isPlaying: _isPlaying,
      audioClips: _project.clips,
    );
  }

  void seekTo(int ms) {
    final total = max(1000, _project.totalDurationMs);
    _playheadMs = ms.clamp(0, total);
    _syncAudio();
    notifyListeners();
  }

  void selectClip(String? id) {
    if (_selectedClipId != id) {
      _selectedClipId = id;
      notifyListeners();
    }
  }

  void setTimelineScale(double scale) {
    _timelineScale = scale.clamp(20.0, 200.0);
    notifyListeners();
  }

  void togglePlay() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    if (_isPlaying) return;
    final total = _project.totalDurationMs;
    if (_playheadMs >= total && total > 0) {
      _playheadMs = 0;
    }
    _isPlaying = true;
    _lastTickTime = DateTime.now();
    _syncAudio();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      final now = DateTime.now();
      final dt = now.difference(_lastTickTime!).inMilliseconds;
      _lastTickTime = now;

      double currentSpeedMultiplier = 1.0;
      for (final c in _project.primaryClips) {
        if (_playheadMs >= c.startMs && _playheadMs < c.endMs) {
          final progress = c.durationMs > 0
              ? (_playheadMs - c.startMs) / c.durationMs
              : 0.0;
          currentSpeedMultiplier = c.getEffectiveSpeedAt(progress);
          break;
        }
      }

      _playheadMs += (dt * currentSpeedMultiplier).round();
      final maxD = _project.totalDurationMs;
      if (_playheadMs >= maxD) {
        _playheadMs = maxD;
        pause();
      }
      _syncAudio();
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    if (!_isPlaying) return;
    _isPlaying = false;
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _syncAudio();
    notifyListeners();
  }

  void addPrimaryClip(TimelineClip clip) {
    _pushUndo();
    final primaries = _project.primaryClips;
    final start = primaries.isEmpty ? 0 : primaries.last.endMs;
    final newClip = clip.copyWith(
      startMs: start,
      isPrimary: true,
      trackIndex: 0,
    );
    _project = _project.copyWith(
      clips: [..._project.clips, newClip],
      modifiedAt: DateTime.now(),
    );
    _project = _project.packPrimaryClips();
    notifyListeners();
    _autoSave();
  }

  void addSecondaryClip(TimelineClip clip) {
    _pushUndo();
    final newClip = clip.copyWith(
      startMs: _playheadMs,
      isPrimary: false,
    );
    _project = _project.copyWith(
      clips: [..._project.clips, newClip],
      modifiedAt: DateTime.now(),
    );
    _selectedClipId = newClip.id;
    notifyListeners();
    _autoSave();

    if (newClip.type == ClipType.audio && newClip.waveformSamples.isEmpty) {
      AudioWaveformService().getWaveformSamples(
        filePath: newClip.assetPath,
        clipId: newClip.id,
        durationMs: newClip.durationMs,
      ).then((samples) {
        final idx = _project.clips.indexWhere((c) => c.id == newClip.id);
        if (idx >= 0) {
          final updated = _project.clips[idx].copyWith(waveformSamples: samples);
          final updatedList = List<TimelineClip>.from(_project.clips);
          updatedList[idx] = updated;
          _project = _project.copyWith(clips: updatedList);
          notifyListeners();
        }
      });
    }
  }

  void updateClip(TimelineClip updated) {
    _pushUndo();
    final index = _project.clips.indexWhere((c) => c.id == updated.id);
    if (index >= 0) {
      final newClips = List<TimelineClip>.from(_project.clips);
      newClips[index] = updated;
      _project = _project.copyWith(
        clips: newClips,
        modifiedAt: DateTime.now(),
      );
      if (updated.isPrimary) {
        _project = _project.packPrimaryClips();
      }
      notifyListeners();
      _autoSave();
    }
  }

  void splitClipAtPlayhead(String clipId) {
    final clip = _project.clips.firstWhere((c) => c.id == clipId);
    if (_playheadMs <= clip.startMs || _playheadMs >= clip.endMs) {
      return; // Not inside clip
    }

    _pushUndo();
    final firstDuration = _playheadMs - clip.startMs;
    final secondDuration = clip.durationMs - firstDuration;
    final now = DateTime.now().millisecondsSinceEpoch;

    final clipA = clip.copyWith(
      durationMs: firstDuration,
      sourceDurationMs: firstDuration,
    );

    final clipB = clip.copyWith(
      id: '${clip.id}_split_$now',
      startMs: _playheadMs,
      durationMs: secondDuration,
      sourceInMs: clip.sourceInMs + firstDuration,
      sourceDurationMs: secondDuration,
    );

    final newClips = <TimelineClip>[];
    for (final c in _project.clips) {
      if (c.id == clipId) {
        newClips.add(clipA);
        newClips.add(clipB);
      } else {
        newClips.add(c);
      }
    }

    _project = _project.copyWith(
      clips: newClips,
      modifiedAt: DateTime.now(),
    );
    if (clip.isPrimary) {
      _project = _project.packPrimaryClips();
    }
    _selectedClipId = clipB.id;
    notifyListeners();
    _autoSave();
  }

  void insertFreezeFrameAtPlayhead({int durationMs = 3000}) {
    TimelineClip? activePrimary;
    for (final c in _project.primaryClips) {
      if (_playheadMs >= c.startMs && _playheadMs < c.endMs) {
        activePrimary = c;
        break;
      }
    }
    if (activePrimary == null) return;

    _pushUndo();
    final now = DateTime.now().millisecondsSinceEpoch;
    final freezeClip = TimelineClip(
      id: 'freeze_${now}_${activePrimary.id}',
      name: 'Freeze Frame (${activePrimary.name})',
      type: activePrimary.type == ClipType.video ? ClipType.image : activePrimary.type,
      startMs: _playheadMs,
      durationMs: durationMs,
      sourceDurationMs: durationMs,
      assetPath: activePrimary.assetPath,
      colorValue: activePrimary.colorValue,
      isPrimary: true,
      filter: activePrimary.filter,
    );

    final firstDuration = _playheadMs - activePrimary.startMs;
    final secondDuration = activePrimary.durationMs - firstDuration;

    final newClips = <TimelineClip>[];
    for (final c in _project.clips) {
      if (c.id == activePrimary.id) {
        if (firstDuration > 200) {
          newClips.add(activePrimary.copyWith(
            durationMs: firstDuration,
            sourceDurationMs: firstDuration,
          ));
        }
        newClips.add(freezeClip);
        if (secondDuration > 200) {
          newClips.add(activePrimary.copyWith(
            id: '${activePrimary.id}_post_freeze_$now',
            durationMs: secondDuration,
            sourceInMs: activePrimary.sourceInMs + firstDuration,
            sourceDurationMs: secondDuration,
          ));
        }
      } else {
        newClips.add(c);
      }
    }

    _project = _project.copyWith(
      clips: newClips,
      modifiedAt: DateTime.now(),
    ).packPrimaryClips();
    _selectedClipId = freezeClip.id;
    notifyListeners();
    _autoSave();
  }

  void addSnapshotAsLayer({int durationMs = 4000}) {
    TimelineClip? activePrimary;
    for (final c in _project.primaryClips) {
      if (_playheadMs >= c.startMs && _playheadMs < c.endMs) {
        activePrimary = c;
        break;
      }
    }

    _pushUndo();
    final now = DateTime.now().millisecondsSinceEpoch;
    final layerClip = TimelineClip(
      id: 'snapshot_layer_$now',
      name: 'Snapshot Layer',
      type: activePrimary?.type == ClipType.video ? ClipType.image : (activePrimary?.type ?? ClipType.color),
      startMs: _playheadMs,
      durationMs: durationMs,
      sourceDurationMs: durationMs,
      assetPath: activePrimary?.assetPath,
      colorValue: activePrimary?.colorValue ?? 0xFF00E5FF,
      isPrimary: false,
      trackIndex: 1,
      scale: 0.65,
    );

    _project = _project.copyWith(
      clips: [..._project.clips, layerClip],
      modifiedAt: DateTime.now(),
    );
    _selectedClipId = layerClip.id;
    notifyListeners();
    _autoSave();
  }

  void trimClipLeft(String clipId) {
    final clip = _project.clips.firstWhere((c) => c.id == clipId);
    if (_playheadMs <= clip.startMs || _playheadMs >= clip.endMs) return;

    _pushUndo();
    final delta = _playheadMs - clip.startMs;
    final updated = clip.copyWith(
      startMs: _playheadMs,
      durationMs: clip.durationMs - delta,
      sourceInMs: clip.sourceInMs + delta,
    );

    updateClip(updated);
  }

  void trimClipRight(String clipId) {
    final clip = _project.clips.firstWhere((c) => c.id == clipId);
    if (_playheadMs <= clip.startMs || _playheadMs >= clip.endMs) return;

    _pushUndo();
    final newDuration = _playheadMs - clip.startMs;
    final updated = clip.copyWith(
      durationMs: newDuration,
    );

    updateClip(updated);
  }

  bool hasKeyframeNearPlayhead(TimelineClip clip) {
    if (_playheadMs < clip.startMs || _playheadMs > clip.endMs) return false;
    final relMs = _playheadMs - clip.startMs;
    return clip.keyframes.any((k) => (k.timeMs - relMs).abs() <= 150);
  }

  void toggleKeyframeAtPlayhead(String clipId) {
    final clip = _project.clips.firstWhere((c) => c.id == clipId);
    if (_playheadMs < clip.startMs || _playheadMs > clip.endMs) return;

    final relMs = (_playheadMs - clip.startMs).clamp(0, clip.durationMs);
    final keyframes = List<Keyframe>.from(clip.keyframes);
    final existingIndex = keyframes.indexWhere((k) => (k.timeMs - relMs).abs() <= 150);

    if (existingIndex >= 0) {
      // Remove keyframe
      keyframes.removeAt(existingIndex);
    } else {
      // Add keyframe with current transform properties
      final newK = Keyframe(
        timeMs: relMs,
        scale: clip.scale,
        rotation: clip.rotation,
        offsetX: clip.offsetX,
        offsetY: clip.offsetY,
        opacity: clip.opacity,
      );
      keyframes.add(newK);
      keyframes.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    }

    updateClip(clip.copyWith(keyframes: keyframes));
  }

  void jumpToPreviousKeyframe(String clipId) {
    final clip = _project.clips.firstWhere((c) => c.id == clipId);
    final relMs = _playheadMs - clip.startMs;
    final sorted = List<Keyframe>.from(clip.keyframes)
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));

    for (int i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].timeMs < relMs - 50) {
        seekTo(clip.startMs + sorted[i].timeMs);
        return;
      }
    }
  }

  void jumpToNextKeyframe(String clipId) {
    final clip = _project.clips.firstWhere((c) => c.id == clipId);
    final relMs = _playheadMs - clip.startMs;
    final sorted = List<Keyframe>.from(clip.keyframes)
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));

    for (final k in sorted) {
      if (k.timeMs > relMs + 50) {
        seekTo(clip.startMs + k.timeMs);
        return;
      }
    }
  }

  void deleteClip(String clipId) {
    _pushUndo();
    final wasPrimary = selectedClip?.isPrimary ?? false;
    final newClips = _project.clips.where((c) => c.id != clipId).toList();
    _project = _project.copyWith(
      clips: newClips,
      modifiedAt: DateTime.now(),
    );
    if (wasPrimary) {
      _project = _project.packPrimaryClips();
    }
    _selectedClipId = null;
    _clampPlayhead();
    notifyListeners();
    _autoSave();
  }

  void duplicateClip(String clipId) {
    final clip = _project.clips.firstWhere((c) => c.id == clipId);
    _pushUndo();
    final now = DateTime.now().millisecondsSinceEpoch;
    final copy = clip.copyWith(
      id: '${clip.id}_copy_$now',
      name: '${clip.name} (Copy)',
      startMs: clip.isPrimary ? clip.endMs : clip.startMs + 500,
    );

    _project = _project.copyWith(
      clips: [..._project.clips, copy],
      modifiedAt: DateTime.now(),
    );
    if (clip.isPrimary) {
      _project = _project.packPrimaryClips();
    }
    _selectedClipId = copy.id;
    notifyListeners();
    _autoSave();
  }

  void duplicateAsLayer(String clipId) {
    final clip = _project.clips.firstWhere((c) => c.id == clipId);
    _pushUndo();
    final now = DateTime.now().millisecondsSinceEpoch;
    final copy = clip.copyWith(
      id: '${clip.id}_layer_$now',
      name: '${clip.name} (Layer)',
      isPrimary: false,
      trackIndex: 1,
      scale: 0.6,
    );

    _project = _project.copyWith(
      clips: [..._project.clips, copy],
      modifiedAt: DateTime.now(),
    );
    _selectedClipId = copy.id;
    notifyListeners();
    _autoSave();
  }

  Future<TimelineClip?> extractAudioFromClip(String clipId) async {
    final clipIndex = _project.clips.indexWhere((c) => c.id == clipId);
    if (clipIndex < 0) return null;
    final videoClip = _project.clips[clipIndex];

    _pushUndo();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Mute original video clip
    final updatedVideo = videoClip.copyWith(isMuted: true);
    final updatedClips = List<TimelineClip>.from(_project.clips);
    updatedClips[clipIndex] = updatedVideo;

    // 2. Extract audio stream
    String? audioPath;
    if (videoClip.assetPath != null) {
      audioPath = await AudioExtractionService().extractAudio(
        videoPath: videoClip.assetPath!,
        clipId: videoClip.id,
      );
    }

    // 3. Create decoupled Audio Clip
    final audioClip = TimelineClip(
      id: 'extracted_audio_${now}_${videoClip.id}',
      name: '${videoClip.name} (Audio)',
      type: ClipType.audio,
      startMs: videoClip.startMs,
      durationMs: videoClip.durationMs,
      sourceInMs: videoClip.sourceInMs,
      sourceDurationMs: videoClip.sourceDurationMs,
      assetPath: audioPath ?? videoClip.assetPath,
      colorValue: 0xFF00E5FF,
      volume: videoClip.volume,
      isPrimary: false,
      trackIndex: 3,
    );

    _project = _project.copyWith(
      clips: [...updatedClips, audioClip],
      modifiedAt: DateTime.now(),
    );
    _selectedClipId = audioClip.id;
    notifyListeners();
    _autoSave();

    // 4. Generate waveforms in background
    AudioWaveformService()
        .getWaveformSamples(
      filePath: audioClip.assetPath,
      clipId: audioClip.id,
      durationMs: audioClip.durationMs,
    )
        .then((samples) {
      final idx = _project.clips.indexWhere((c) => c.id == audioClip.id);
      if (idx >= 0) {
        final withWave = _project.clips[idx].copyWith(waveformSamples: samples);
        final list = List<TimelineClip>.from(_project.clips);
        list[idx] = withWave;
        _project = _project.copyWith(clips: list);
        notifyListeners();
      }
    });

    return audioClip;
  }

  void bringToFront(String clipId) {
    final clip = _project.clips.firstWhere((c) => c.id == clipId);
    if (clip.isPrimary) return;
    _pushUndo();
    final nonSelected = _project.clips.where((c) => c.id != clipId).toList();
    _project = _project.copyWith(
      clips: [...nonSelected, clip],
      modifiedAt: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  void sendToBack(String clipId) {
    final clip = _project.clips.firstWhere((c) => c.id == clipId);
    if (clip.isPrimary) return;
    _pushUndo();
    final primaries = _project.primaryClips;
    final otherSecondaries = _project.secondaryClips.where((c) => c.id != clipId).toList();
    _project = _project.copyWith(
      clips: [...primaries, clip, ...otherSecondaries],
      modifiedAt: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  void reorderSecondaryClips(int oldIndex, int newIndex) {
    final secondaries = List<TimelineClip>.from(_project.secondaryClips);
    if (oldIndex < 0 || oldIndex >= secondaries.length) return;
    if (newIndex > secondaries.length) newIndex = secondaries.length;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    _pushUndo();
    final item = secondaries.removeAt(oldIndex);
    secondaries.insert(newIndex, item);
    _project = _project.copyWith(
      clips: [..._project.primaryClips, ...secondaries],
      modifiedAt: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  void applyPipPreset(String clipId, PipPreset preset) {
    final clip = _project.clips.firstWhere((c) => c.id == clipId);
    _pushUndo();
    final updated = clip.copyWith(
      pipPreset: preset,
      scale: preset == PipPreset.none ? clip.scale : preset.defaultScale,
      offsetX: preset == PipPreset.none ? clip.offsetX : preset.defaultOffsetX,
      offsetY: preset == PipPreset.none ? clip.offsetY : preset.defaultOffsetY,
    );
    updateClip(updated);
  }

  void updateSettings(dynamic newSettings) {
    _pushUndo();
    _project = _project.copyWith(
      settings: newSettings,
      modifiedAt: DateTime.now(),
    );
    notifyListeners();
    _autoSave();
  }

  void _autoSave() {
    ProjectStorageService.instance.saveProject(_project);
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    AudioPlaybackService.instance.dispose();
    super.dispose();
  }
}
