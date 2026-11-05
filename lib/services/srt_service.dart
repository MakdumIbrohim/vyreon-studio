import '../models/subtitle_entry.dart';

class SrtService {
  static List<SubtitleEntry> parseSrt(String content) {
    final entries = <SubtitleEntry>[];
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final blocks = normalized.split('\n\n');

    int fallbackIndex = 1;

    for (final block in blocks) {
      final lines = block
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.length < 2) continue;

      int idx = fallbackIndex;
      int lineOffset = 0;

      // Check if line 0 is numeric index
      final parsedIdx = int.tryParse(lines[0]);
      if (parsedIdx != null) {
        idx = parsedIdx;
        lineOffset = 1;
      }

      if (lines.length <= lineOffset) continue;

      final timeLine = lines[lineOffset];
      final parts = timeLine.split('-->');
      if (parts.length != 2) continue;

      final startMs = parseTimestamp(parts[0].trim());
      final endMs = parseTimestamp(parts[1].trim());

      final textLines = lines.sublist(lineOffset + 1);
      final text = textLines.join('\n');

      entries.add(SubtitleEntry(
        index: idx,
        startMs: startMs,
        endMs: endMs,
        text: text,
      ));
      fallbackIndex = idx + 1;
    }

    entries.sort((a, b) => a.startMs.compareTo(b.startMs));
    return entries;
  }

  static String exportSrt(List<SubtitleEntry> entries) {
    final sorted = List<SubtitleEntry>.from(entries)
      ..sort((a, b) => a.startMs.compareTo(b.startMs));

    final buffer = StringBuffer();
    for (int i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      buffer.writeln('${i + 1}');
      buffer.writeln(
          '${formatTimestamp(entry.startMs)} --> ${formatTimestamp(entry.endMs)}');
      buffer.writeln(entry.text);
      buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  static String formatTimestamp(int ms) {
    final hours = ms ~/ 3600000;
    final minutes = (ms % 3600000) ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    final millis = ms % 1000;

    final h = hours.toString().padLeft(2, '0');
    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');
    final msStr = millis.toString().padLeft(3, '0');

    return '$h:$m:$s,$msStr';
  }

  static int parseTimestamp(String timestamp) {
    // Expected format: HH:mm:ss,SSS or HH:mm:ss.SSS or mm:ss,SSS
    final cleaned = timestamp.replaceAll(',', '.').trim();
    final parts = cleaned.split(':');
    if (parts.isEmpty) return 0;

    double totalSeconds = 0.0;
    if (parts.length == 3) {
      final h = double.tryParse(parts[0]) ?? 0.0;
      final m = double.tryParse(parts[1]) ?? 0.0;
      final s = double.tryParse(parts[2]) ?? 0.0;
      totalSeconds = (h * 3600) + (m * 60) + s;
    } else if (parts.length == 2) {
      final m = double.tryParse(parts[0]) ?? 0.0;
      final s = double.tryParse(parts[1]) ?? 0.0;
      totalSeconds = (m * 60) + s;
    } else {
      totalSeconds = double.tryParse(parts[0]) ?? 0.0;
    }

    return (totalSeconds * 1000).round();
  }
}
