class ProjectSettings {
  final double defaultPhotoDuration; // in seconds, default 4.5
  final double defaultTransitionDuration; // in seconds, default 1.5
  final double audioFadeInDuration; // in seconds, default 0.0
  final double audioFadeOutDuration; // in seconds, default 0.0
  final bool autoMasterVolume;

  const ProjectSettings({
    this.defaultPhotoDuration = 4.5,
    this.defaultTransitionDuration = 1.5,
    this.audioFadeInDuration = 0.0,
    this.audioFadeOutDuration = 0.0,
    this.autoMasterVolume = true,
  });

  ProjectSettings copyWith({
    double? defaultPhotoDuration,
    double? defaultTransitionDuration,
    double? audioFadeInDuration,
    double? audioFadeOutDuration,
    bool? autoMasterVolume,
  }) {
    return ProjectSettings(
      defaultPhotoDuration: defaultPhotoDuration ?? this.defaultPhotoDuration,
      defaultTransitionDuration:
          defaultTransitionDuration ?? this.defaultTransitionDuration,
      audioFadeInDuration: audioFadeInDuration ?? this.audioFadeInDuration,
      audioFadeOutDuration: audioFadeOutDuration ?? this.audioFadeOutDuration,
      autoMasterVolume: autoMasterVolume ?? this.autoMasterVolume,
    );
  }

  Map<String, dynamic> toJson() => {
    'defaultPhotoDuration': defaultPhotoDuration,
    'defaultTransitionDuration': defaultTransitionDuration,
    'audioFadeInDuration': audioFadeInDuration,
    'audioFadeOutDuration': audioFadeOutDuration,
    'autoMasterVolume': autoMasterVolume,
  };

  factory ProjectSettings.fromJson(Map<String, dynamic> json) {
    return ProjectSettings(
      defaultPhotoDuration:
          (json['defaultPhotoDuration'] as num?)?.toDouble() ?? 4.5,
      defaultTransitionDuration:
          (json['defaultTransitionDuration'] as num?)?.toDouble() ?? 1.5,
      audioFadeInDuration:
          (json['audioFadeInDuration'] as num?)?.toDouble() ?? 0.0,
      audioFadeOutDuration:
          (json['audioFadeOutDuration'] as num?)?.toDouble() ?? 0.0,
      autoMasterVolume: json['autoMasterVolume'] as bool? ?? true,
    );
  }
}
