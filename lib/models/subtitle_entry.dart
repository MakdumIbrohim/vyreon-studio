class SubtitleEntry {
  final int index;
  final int startMs;
  final int endMs;
  final String text;

  const SubtitleEntry({
    required this.index,
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  int get durationMs => endMs - startMs;

  Map<String, dynamic> toJson() => {
        'index': index,
        'startMs': startMs,
        'endMs': endMs,
        'text': text,
      };

  factory SubtitleEntry.fromJson(Map<String, dynamic> json) => SubtitleEntry(
        index: json['index'] as int? ?? 1,
        startMs: json['startMs'] as int? ?? 0,
        endMs: json['endMs'] as int? ?? 1000,
        text: json['text'] as String? ?? '',
      );

  SubtitleEntry copyWith({
    int? index,
    int? startMs,
    int? endMs,
    String? text,
  }) {
    return SubtitleEntry(
      index: index ?? this.index,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      text: text ?? this.text,
    );
  }
}
