import 'dart:math';
import 'aspect_ratio.dart';
import 'project_settings.dart';
import 'subtitle_entry.dart';
import 'timeline_clip.dart';

class Project {
  final String id;
  final String name;
  final ProjectAspectRatio aspectRatio;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final ProjectSettings settings;
  final List<TimelineClip> clips;
  final List<SubtitleEntry> subtitles;

  const Project({
    required this.id,
    required this.name,
    required this.aspectRatio,
    required this.createdAt,
    required this.modifiedAt,
    this.settings = const ProjectSettings(),
    this.clips = const [],
    this.subtitles = const [],
  });

  int get totalDurationMs {
    if (clips.isEmpty) return 0;
    int maxEnd = 0;
    for (final c in clips) {
      maxEnd = max(maxEnd, c.endMs);
    }
    return maxEnd;
  }

  List<TimelineClip> get primaryClips =>
      clips.where((c) => c.isPrimary).toList()
        ..sort((a, b) => a.startMs.compareTo(b.startMs));

  List<TimelineClip> get secondaryClips =>
      clips.where((c) => !c.isPrimary).toList();

  Project copyWith({
    String? id,
    String? name,
    ProjectAspectRatio? aspectRatio,
    DateTime? createdAt,
    DateTime? modifiedAt,
    ProjectSettings? settings,
    List<TimelineClip>? clips,
    List<SubtitleEntry>? subtitles,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      settings: settings ?? this.settings,
      clips: clips ?? this.clips,
      subtitles: subtitles ?? this.subtitles,
    );
  }

  /// Ensures primary track clips are contiguous without unintentional gaps.
  Project packPrimaryClips() {
    final primaries = primaryClips;
    final secondaries = clips.where((c) => !c.isPrimary).toList();

    int cursor = 0;
    final updatedPrimaries = <TimelineClip>[];
    for (final p in primaries) {
      updatedPrimaries.add(p.copyWith(startMs: cursor));
      cursor += p.durationMs;
    }

    return copyWith(
      clips: [...updatedPrimaries, ...secondaries],
      modifiedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'aspectRatio': aspectRatio.label,
    'createdAt': createdAt.toIso8601String(),
    'modifiedAt': modifiedAt.toIso8601String(),
    'settings': settings.toJson(),
    'clips': clips.map((c) => c.toJson()).toList(),
    'subtitles': subtitles.map((s) => s.toJson()).toList(),
  };

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      aspectRatio: ProjectAspectRatio.fromString(
        json['aspectRatio'] as String? ?? '16:9',
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      modifiedAt:
          DateTime.tryParse(json['modifiedAt'] as String? ?? '') ??
          DateTime.now(),
      settings: json['settings'] != null
          ? ProjectSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const ProjectSettings(),
      clips: (json['clips'] as List<dynamic>?)
              ?.map((c) => TimelineClip.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      subtitles: (json['subtitles'] as List<dynamic>?)
              ?.map((s) => SubtitleEntry.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static Project createSample(String name, ProjectAspectRatio ratio) {
    final now = DateTime.now();
    return Project(
      id: 'proj_${now.millisecondsSinceEpoch}',
      name: name,
      aspectRatio: ratio,
      createdAt: now,
      modifiedAt: now,
      clips: [
        TimelineClip(
          id: 'clip_sample_1',
          name: 'Intro Neon',
          type: ClipType.color,
          startMs: 0,
          durationMs: 4000,
          sourceDurationMs: 4000,
          colorValue: 0xFF1E88E5, // Ocean Blue
          isPrimary: true,
        ),
        TimelineClip(
          id: 'clip_sample_2',
          name: 'Sunset Glow',
          type: ClipType.color,
          startMs: 4000,
          durationMs: 5000,
          sourceDurationMs: 5000,
          colorValue: 0xFFE64A19, // Deep Orange
          isPrimary: true,
        ),
        TimelineClip(
          id: 'clip_sample_3',
          name: 'Cyber Grid',
          type: ClipType.color,
          startMs: 9000,
          durationMs: 4000,
          sourceDurationMs: 4000,
          colorValue: 0xFF43A047, // Forest Green
          isPrimary: true,
        ),
        TimelineClip(
          id: 'clip_text_1',
          name: 'Title Card',
          type: ClipType.text,
          startMs: 500,
          durationMs: 3000,
          sourceDurationMs: 3000,
          textContent: 'VYREON STUDIO',
          colorValue: 0xFFFFFFFF,
          fontSize: 32.0,
          offsetY: -0.2,
          isPrimary: false,
          trackIndex: 1,
        ),
        TimelineClip(
          id: 'clip_audio_1',
          name: 'Cinematic Beat',
          type: ClipType.audio,
          startMs: 0,
          durationMs: 13000,
          sourceDurationMs: 13000,
          colorValue: 0xFFFFB300,
          volume: 0.8,
          isPrimary: false,
          trackIndex: 2,
        ),
      ],
    );
  }
}
