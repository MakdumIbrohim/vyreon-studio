import 'dart:io';

class VideoReverseService {
  static final VideoReverseService _instance = VideoReverseService._internal();
  factory VideoReverseService() => _instance;
  VideoReverseService._internal();

  Directory _getReversedDir() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    final dir = home.isNotEmpty
        ? Directory('$home/.vyreon_studio/reversed_videos')
        : Directory('${Directory.systemTemp.path}/vyreon_reversed_videos');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Reverses both video and audio streams using native FFmpeg
  Future<String?> reverseVideoClip({
    required String inputPath,
    required String clipId,
  }) async {
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) return null;

    try {
      final outDir = _getReversedDir();
      final now = DateTime.now().millisecondsSinceEpoch;
      final safeName = clipId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final outPath = '${outDir.path}/rev_${safeName}_$now.mp4';

      final result = await Process.run(
        'ffmpeg',
        [
          '-y',
          '-i',
          inputPath,
          '-vf',
          'reverse',
          '-af',
          'areverse',
          '-preset',
          'ultrafast',
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
