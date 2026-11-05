import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';

class AudioRecordingService {
  static final AudioRecordingService instance = AudioRecordingService._();
  AudioRecordingService._();

  AudioRecorder? _audioRecorder;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Directory _getRecordingDirectory() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    final dir = Directory('$home/.vyreon_studio/recordings');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<bool> hasPermission() async {
    _audioRecorder ??= AudioRecorder();
    try {
      return await _audioRecorder!.hasPermission();
    } catch (_) {
      return false;
    }
  }

  Future<String> startRecording() async {
    _audioRecorder ??= AudioRecorder();
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      throw Exception('Microphone permission not granted.');
    }

    final dir = _getRecordingDirectory();
    final now = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/voiceover_$now.m4a';

    await _audioRecorder!.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
    _isRecording = true;
    return path;
  }

  Future<String?> stopRecording() async {
    if (_audioRecorder == null || !_isRecording) return null;
    try {
      final path = await _audioRecorder!.stop();
      _isRecording = false;
      return path;
    } catch (_) {
      _isRecording = false;
      return null;
    }
  }

  Stream<Amplitude>? getAmplitudeStream() {
    if (_audioRecorder == null) return null;
    return _audioRecorder!.onAmplitudeChanged(const Duration(milliseconds: 100));
  }

  Future<void> dispose() async {
    try {
      await _audioRecorder?.dispose();
    } catch (_) {}
    _audioRecorder = null;
    _isRecording = false;
  }
}
