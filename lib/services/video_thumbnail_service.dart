import 'dart:io';

class VideoThumbnailService {
  static final VideoThumbnailService _instance =
      VideoThumbnailService._internal();
  factory VideoThumbnailService() => _instance;
  VideoThumbnailService._internal();

  final Map<String, String> _thumbnailCache = {};

  Directory _getCacheDir() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    final dir = home.isNotEmpty
        ? Directory('$home/.vyreon_studio/thumbnails')
        : Directory('${Directory.systemTemp.path}/vyreon_thumbnails');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  String _sanitizeHash(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  }

  /// Extracts or returns cached JPEG thumbnail file for a given video path
  Future<File?> getThumbnailFile(String videoPath, {int atMs = 1000}) async {
    final videoFile = File(videoPath);
    if (!videoFile.existsSync()) return null;

    final cacheKey = '${videoPath}_$atMs';
    if (_thumbnailCache.containsKey(cacheKey)) {
      final cachedFile = File(_thumbnailCache[cacheKey]!);
      if (cachedFile.existsSync()) return cachedFile;
    }

    try {
      final cacheDir = _getCacheDir();
      final safeName = _sanitizeHash(videoFile.uri.pathSegments.last);
      final outPath = '${cacheDir.path}/${safeName}_${atMs}ms.jpg';
      final outFile = File(outPath);

      if (outFile.existsSync() && outFile.lengthSync() > 100) {
        _thumbnailCache[cacheKey] = outPath;
        return outFile;
      }

      // Convert ms to HH:MM:SS.mmm
      final seconds = (atMs / 1000.0).clamp(0.0, 7200.0);
      final timeStr = seconds.toStringAsFixed(3);

      final result = await Process.run(
        'ffmpeg',
        [
          '-ss',
          timeStr,
          '-i',
          videoPath,
          '-frames:v',
          '1',
          '-q:v',
          '3',
          '-vf',
          'scale=480:-1',
          outPath,
          '-y',
        ],
      );

      if (result.exitCode == 0 && outFile.existsSync()) {
        _thumbnailCache[cacheKey] = outPath;
        return outFile;
      }
    } catch (_) {
      // Fallback gracefully if ffmpeg is unavailable on target platform
    }
    return null;
  }

  /// Probes exact media duration in milliseconds using ffprobe
  Future<int?> probeDurationMs(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    try {
      final result = await Process.run(
        'ffprobe',
        [
          '-v',
          'error',
          '-show_entries',
          'format=duration',
          '-of',
          'default=noprint_wrappers=1:nokey=1',
          filePath,
        ],
      );

      if (result.exitCode == 0) {
        final raw = result.stdout.toString().trim();
        final sec = double.tryParse(raw);
        if (sec != null && sec > 0) {
          return (sec * 1000).round();
        }
      }
    } catch (_) {}
    return null;
  }
}
