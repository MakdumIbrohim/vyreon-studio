import 'dart:io';

class AudioExtractionService {
  static final AudioExtractionService _instance =
      AudioExtractionService._internal();
  factory AudioExtractionService() => _instance;
  AudioExtractionService._internal();

  Directory _getAudioDir() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    final dir = home.isNotEmpty
        ? Directory('$home/.vyreon_studio/extracted_audio')
        : Directory('${Directory.systemTemp.path}/vyreon_extracted_audio');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Extracts audio stream from a video file into an AAC/M4A audio file
  Future<String?> extractAudio({
    required String videoPath,
    required String clipId,
  }) async {
    final videoFile = File(videoPath);
    if (!videoFile.existsSync()) return null;

    try {
      final outDir = _getAudioDir();
      final now = DateTime.now().millisecondsSinceEpoch;
      final safeName = clipId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final outPath = '${outDir.path}/audio_${safeName}_$now.m4a';

      // Extract native audio track using ffmpeg
      final result = await Process.run(
        'ffmpeg',
        [
          '-y',
          '-i',
          videoPath,
          '-vn',
          '-c:a',
          'aac',
          '-b:a',
          '192k',
          outPath,
        ],
      );

      final outFile = File(outPath);
      if (result.exitCode == 0 && outFile.existsSync() && outFile.lengthSync() > 100) {
        return outPath;
      }
    } catch (_) {}
    return null;
  }
}
