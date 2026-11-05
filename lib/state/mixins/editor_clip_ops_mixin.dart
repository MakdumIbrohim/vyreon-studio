import 'dart:math';
import '../../models/subtitle_entry.dart';
import '../../models/timeline_clip.dart';
import '../../services/audio_extraction_service.dart';
import '../../services/audio_waveform_service.dart';
import '../../services/rust_engine_service.dart';
import '../../services/srt_service.dart';
import '../../services/video_reverse_service.dart';
import '../editor_controller_base.dart';

mixin EditorClipOpsMixin on EditorControllerBase {
  void addPrimaryClip(TimelineClip clip) {
    pushUndo();
    final primaries = project.primaryClips;
    final start = primaries.isEmpty ? 0 : primaries.last.endMs;
    final newClip = clip.copyWith(
      startMs: start,
      isPrimary: true,
      trackIndex: 0,
    );
    project = project.copyWith(
      clips: [...project.clips, newClip],
      modifiedAt: DateTime.now(),
    ).packPrimaryClips();
    notifyListeners();
    autoSave();
  }

  void addSecondaryClip(TimelineClip clip) {
    pushUndo();
    final newClip = clip.copyWith(
      startMs: playheadMs,
      isPrimary: false,
    );
    project = project.copyWith(
      clips: [...project.clips, newClip],
      modifiedAt: DateTime.now(),
    );
    selectedClipId = newClip.id;
    notifyListeners();
    autoSave();

    if (newClip.type == ClipType.audio && newClip.waveformSamples.isEmpty) {
      AudioWaveformService()
          .getWaveformSamples(
        filePath: newClip.assetPath,
        clipId: newClip.id,
        durationMs: newClip.durationMs,
      )
          .then((samples) {
        final idx = project.clips.indexWhere((c) => c.id == newClip.id);
        if (idx >= 0) {
          final updated = project.clips[idx].copyWith(waveformSamples: samples);
          final updatedList = List<TimelineClip>.from(project.clips);
          updatedList[idx] = updated;
          project = project.copyWith(clips: updatedList);
          notifyListeners();
        }
      });
    }
  }

  void updateClip(TimelineClip updated) {
    pushUndo();
    final index = project.clips.indexWhere((c) => c.id == updated.id);
    if (index >= 0) {
      final newClips = List<TimelineClip>.from(project.clips);
      newClips[index] = updated;
      project = project.copyWith(
        clips: newClips,
        modifiedAt: DateTime.now(),
      );
      if (updated.isPrimary) {
        project = project.packPrimaryClips();
      }
      notifyListeners();
      autoSave();
    }
  }

  void updateClipLive(TimelineClip updated) {
    final index = project.clips.indexWhere((c) => c.id == updated.id);
    if (index >= 0) {
      final newClips = List<TimelineClip>.from(project.clips);
      newClips[index] = updated;
      project = project.copyWith(
        clips: newClips,
        modifiedAt: DateTime.now(),
      );
      if (updated.isPrimary) {
        project = project.packPrimaryClips();
      }
      notifyListeners();
    }
  }

  void splitClipAtPlayhead(String clipId) {
    final clip = project.clips.firstWhere((c) => c.id == clipId);
    if (playheadMs <= clip.startMs || playheadMs >= clip.endMs) {
      return;
    }

    pushUndo();
    final firstDuration = playheadMs - clip.startMs;
    final secondDuration = clip.durationMs - firstDuration;
    final now = DateTime.now().millisecondsSinceEpoch;

    final clipA = clip.copyWith(
      durationMs: firstDuration,
      sourceDurationMs: firstDuration,
    );

    final clipB = clip.copyWith(
      id: '${clip.id}_split_$now',
      startMs: playheadMs,
      durationMs: secondDuration,
      sourceInMs: clip.sourceInMs + firstDuration,
      sourceDurationMs: secondDuration,
    );

    final newClips = <TimelineClip>[];
    for (final c in project.clips) {
      if (c.id == clipId) {
        newClips.add(clipA);
        newClips.add(clipB);
      } else {
        newClips.add(c);
      }
    }

    project = project.copyWith(
      clips: newClips,
      modifiedAt: DateTime.now(),
    );
    if (clip.isPrimary) {
      project = project.packPrimaryClips();
    }
    selectedClipId = clipB.id;
    notifyListeners();
    autoSave();
  }

  void insertFreezeFrameAtPlayhead({int durationMs = 3000}) {
    TimelineClip? activePrimary;
    for (final c in project.primaryClips) {
      if (playheadMs >= c.startMs && playheadMs < c.endMs) {
        activePrimary = c;
        break;
      }
    }
    if (activePrimary == null) return;

    pushUndo();
    final now = DateTime.now().millisecondsSinceEpoch;
    final freezeClip = TimelineClip(
      id: 'freeze_${now}_${activePrimary.id}',
      name: 'Freeze Frame (${activePrimary.name})',
      type: activePrimary.type == ClipType.video ? ClipType.image : activePrimary.type,
      startMs: playheadMs,
      durationMs: durationMs,
      sourceDurationMs: durationMs,
      assetPath: activePrimary.assetPath,
      colorValue: activePrimary.colorValue,
      isPrimary: true,
      filter: activePrimary.filter,
    );

    final firstDuration = playheadMs - activePrimary.startMs;
    final secondDuration = activePrimary.durationMs - firstDuration;

    final newClips = <TimelineClip>[];
    for (final c in project.clips) {
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

    project = project.copyWith(
      clips: newClips,
      modifiedAt: DateTime.now(),
    ).packPrimaryClips();
    selectedClipId = freezeClip.id;
    notifyListeners();
    autoSave();
  }

  void addSnapshotAsLayer({int durationMs = 4000}) {
    TimelineClip? activePrimary;
    for (final c in project.primaryClips) {
      if (playheadMs >= c.startMs && playheadMs < c.endMs) {
        activePrimary = c;
        break;
      }
    }

    pushUndo();
    final now = DateTime.now().millisecondsSinceEpoch;
    final layerClip = TimelineClip(
      id: 'snapshot_layer_$now',
      name: 'Snapshot Layer',
      type: activePrimary?.type == ClipType.video ? ClipType.image : (activePrimary?.type ?? ClipType.color),
      startMs: playheadMs,
      durationMs: durationMs,
      sourceDurationMs: durationMs,
      assetPath: activePrimary?.assetPath,
      colorValue: activePrimary?.colorValue ?? 0xFF00E5FF,
      isPrimary: false,
      trackIndex: 1,
      scale: 0.65,
    );

    project = project.copyWith(
      clips: [...project.clips, layerClip],
      modifiedAt: DateTime.now(),
    );
    selectedClipId = layerClip.id;
    notifyListeners();
    autoSave();
  }

  void trimClipLeft(String clipId) {
    final clip = project.clips.firstWhere((c) => c.id == clipId);
    if (playheadMs <= clip.startMs || playheadMs >= clip.endMs) return;

    pushUndo();
    final delta = playheadMs - clip.startMs;
    final updated = clip.copyWith(
      startMs: playheadMs,
      durationMs: clip.durationMs - delta,
      sourceInMs: clip.sourceInMs + delta,
    );

    updateClip(updated);
  }

  void trimClipRight(String clipId) {
    final clip = project.clips.firstWhere((c) => c.id == clipId);
    if (playheadMs <= clip.startMs || playheadMs >= clip.endMs) return;

    pushUndo();
    final newDuration = playheadMs - clip.startMs;
    final updated = clip.copyWith(
      durationMs: newDuration,
    );

    updateClip(updated);
  }

  bool hasKeyframeNearPlayhead(TimelineClip clip) {
    if (playheadMs < clip.startMs || playheadMs > clip.endMs) return false;
    final relMs = playheadMs - clip.startMs;
    return clip.keyframes.any((k) => (k.timeMs - relMs).abs() <= 150);
  }

  void toggleKeyframeAtPlayhead(String clipId) {
    final clip = project.clips.firstWhere((c) => c.id == clipId);
    if (playheadMs < clip.startMs || playheadMs > clip.endMs) return;

    final relMs = (playheadMs - clip.startMs).clamp(0, clip.durationMs);
    final keyframes = List<Keyframe>.from(clip.keyframes);
    final existingIndex =
        keyframes.indexWhere((k) => (k.timeMs - relMs).abs() <= 150);

    if (existingIndex >= 0) {
      keyframes.removeAt(existingIndex);
    } else {
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
    final clip = project.clips.firstWhere((c) => c.id == clipId);
    final relMs = playheadMs - clip.startMs;
    final sorted = List<Keyframe>.from(clip.keyframes)
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));

    for (int i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].timeMs < relMs - 50) {
        final total = max(1000, project.totalDurationMs);
        playheadMs = (clip.startMs + sorted[i].timeMs).clamp(0, total);
        syncAudio();
        notifyListeners();
        return;
      }
    }
  }

  void jumpToNextKeyframe(String clipId) {
    final clip = project.clips.firstWhere((c) => c.id == clipId);
    final relMs = playheadMs - clip.startMs;
    final sorted = List<Keyframe>.from(clip.keyframes)
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));

    for (final k in sorted) {
      if (k.timeMs > relMs + 50) {
        final total = max(1000, project.totalDurationMs);
        playheadMs = (clip.startMs + k.timeMs).clamp(0, total);
        syncAudio();
        notifyListeners();
        return;
      }
    }
  }

  void deleteClip(String clipId) {
    pushUndo();
    final wasPrimary = project.clips.any((c) => c.id == clipId && c.isPrimary);
    final newClips = project.clips.where((c) => c.id != clipId).toList();
    project = project.copyWith(
      clips: newClips,
      modifiedAt: DateTime.now(),
    );
    if (wasPrimary) {
      project = project.packPrimaryClips();
    }
    selectedClipId = null;
    clampPlayhead();
    notifyListeners();
    autoSave();
  }

  void duplicateClip(String clipId) {
    final clip = project.clips.firstWhere((c) => c.id == clipId);
    pushUndo();
    final now = DateTime.now().millisecondsSinceEpoch;
    final copy = clip.copyWith(
      id: '${clip.id}_copy_$now',
      name: '${clip.name} (Copy)',
      startMs: clip.isPrimary ? clip.endMs : clip.startMs + 500,
    );

    project = project.copyWith(
      clips: [...project.clips, copy],
      modifiedAt: DateTime.now(),
    );
    if (clip.isPrimary) {
      project = project.packPrimaryClips();
    }
    selectedClipId = copy.id;
    notifyListeners();
    autoSave();
  }

  void duplicateAsLayer(String clipId) {
    final clip = project.clips.firstWhere((c) => c.id == clipId);
    pushUndo();
    final now = DateTime.now().millisecondsSinceEpoch;
    final copy = clip.copyWith(
      id: '${clip.id}_layer_$now',
      name: '${clip.name} (Layer)',
      isPrimary: false,
      trackIndex: 1,
      scale: 0.6,
    );

    project = project.copyWith(
      clips: [...project.clips, copy],
      modifiedAt: DateTime.now(),
    );
    selectedClipId = copy.id;
    notifyListeners();
    autoSave();
  }

  Future<TimelineClip?> extractAudioFromClip(String clipId) async {
    final clipIndex = project.clips.indexWhere((c) => c.id == clipId);
    if (clipIndex < 0) return null;
    final videoClip = project.clips[clipIndex];

    pushUndo();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Mute original video clip
    final updatedVideo = videoClip.copyWith(isMuted: true);
    final updatedClips = List<TimelineClip>.from(project.clips);
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

    project = project.copyWith(
      clips: [...updatedClips, audioClip],
      modifiedAt: DateTime.now(),
    );
    selectedClipId = audioClip.id;
    notifyListeners();
    autoSave();

    // 4. Generate waveforms in background
    AudioWaveformService()
        .getWaveformSamples(
      filePath: audioClip.assetPath,
      clipId: audioClip.id,
      durationMs: audioClip.durationMs,
    )
        .then((samples) {
      final idx = project.clips.indexWhere((c) => c.id == audioClip.id);
      if (idx >= 0) {
        final withWave = project.clips[idx].copyWith(waveformSamples: samples);
        final list = List<TimelineClip>.from(project.clips);
        list[idx] = withWave;
        project = project.copyWith(clips: list);
        notifyListeners();
      }
    });

    return audioClip;
  }

  Future<bool> reverseClip(String clipId) async {
    final clipIndex = project.clips.indexWhere((c) => c.id == clipId);
    if (clipIndex < 0) return false;
    final clip = project.clips[clipIndex];

    pushUndo();
    String? reversedPath;
    if (clip.assetPath != null) {
      reversedPath = await VideoReverseService().reverseVideoClip(
        inputPath: clip.assetPath!,
        clipId: clip.id,
      );
    }

    final updated = clip.copyWith(
      assetPath: reversedPath ?? clip.assetPath,
      name: clip.name.contains('(Reversed)')
          ? clip.name.replaceAll(' (Reversed)', '')
          : '${clip.name} (Reversed)',
    );

    updateClip(updated);
    return true;
  }

  void addSubtitle(SubtitleEntry entry) {
    pushUndo();
    final updated = List<SubtitleEntry>.from(project.subtitles)..add(entry);
    updated.sort((a, b) => a.startMs.compareTo(b.startMs));
    project = project.copyWith(
      subtitles: updated,
      modifiedAt: DateTime.now(),
    );
    notifyListeners();
    autoSave();
  }

  void updateSubtitle(SubtitleEntry updatedEntry) {
    pushUndo();
    final list = List<SubtitleEntry>.from(project.subtitles);
    final idx = list.indexWhere((s) => s.index == updatedEntry.index);
    if (idx >= 0) {
      list[idx] = updatedEntry;
      list.sort((a, b) => a.startMs.compareTo(b.startMs));
      project = project.copyWith(
        subtitles: list,
        modifiedAt: DateTime.now(),
      );
      notifyListeners();
      autoSave();
    }
  }

  void deleteSubtitle(int index) {
    pushUndo();
    final list = project.subtitles.where((s) => s.index != index).toList();
    project = project.copyWith(
      subtitles: list,
      modifiedAt: DateTime.now(),
    );
    notifyListeners();
    autoSave();
  }

  void importSrt(String srtContent) {
    pushUndo();
    final entries = SrtService.parseSrt(srtContent);
    project = project.copyWith(
      subtitles: entries,
      modifiedAt: DateTime.now(),
    );
    notifyListeners();
    autoSave();
  }

  void detectBeatsForClip(String clipId, {double thresholdMultiplier = 1.25}) {
    final clipIndex = project.clips.indexWhere((c) => c.id == clipId);
    if (clipIndex < 0) return;
    final clip = project.clips[clipIndex];
    if (clip.waveformSamples.isEmpty) return;

    pushUndo();
    final beats = RustEngineService.instance.detectBeatPeaks(
      peaks: clip.waveformSamples,
      durationMs: clip.durationMs,
      thresholdMultiplier: thresholdMultiplier,
    );

    final updated = clip.copyWith(beatMarkers: beats);
    updateClip(updated);
  }

  void toggleBeatMarkerAtPlayhead(String clipId) {
    final clipIndex = project.clips.indexWhere((c) => c.id == clipId);
    if (clipIndex < 0) return;
    final clip = project.clips[clipIndex];
    if (playheadMs < clip.startMs || playheadMs > clip.endMs) return;

    pushUndo();
    final relMs = playheadMs - clip.startMs;
    final markers = List<int>.from(clip.beatMarkers);
    final existingIdx = markers.indexWhere((b) => (b - relMs).abs() <= 100);

    if (existingIdx >= 0) {
      markers.removeAt(existingIdx);
    } else {
      markers.add(relMs);
      markers.sort();
    }
    updateClip(clip.copyWith(beatMarkers: markers));
  }
}
