import 'dart:io';
import '../models/clip_types.dart';
import '../models/project.dart';

class FfmpegAudioResult {
  final List<String> audioLabels;
  final String finalAudioHead;
  final int nextInputIdx;

  const FfmpegAudioResult({
    required this.audioLabels,
    required this.finalAudioHead,
    required this.nextInputIdx,
  });
}

class FfmpegAudioPipeline {
  static FfmpegAudioResult build({
    required Project project,
    required List<String> args,
    required List<String> filterParts,
    required int startInputIdx,
  }) {
    final secondaryClips = project.secondaryClips;
    final audioClips =
        secondaryClips.where((c) => c.type == ClipType.audio).toList();
    final audioLabels = <String>[];
    int inputIdx = startInputIdx;

    int audioCounter = 0;
    for (final audio in audioClips) {
      if (audio.assetPath != null && File(audio.assetPath!).existsSync()) {
        final durSec = (audio.durationMs / 1000.0).toStringAsFixed(3);
        final inSec = (audio.sourceInMs / 1000.0).toStringAsFixed(3);
        args.addAll(['-ss', inSec, '-t', durSec, '-i', audio.assetPath!]);

        final label = 'a_track_$audioCounter';
        final delayMs = audio.startMs;
        final vol = audio.isMuted ? 0.0 : audio.volume;

        final clipFilters = <String>[
          'adelay=$delayMs|$delayMs',
          'volume=$vol',
        ];

        if (audio.denoisePreset.ffmpegFilter != null) {
          clipFilters.add(audio.denoisePreset.ffmpegFilter!);
        }
        if (audio.enhancePreset.ffmpegFilter != null) {
          clipFilters.add(audio.enhancePreset.ffmpegFilter!);
        }
        if (audio.reverbPreset.ffmpegFilter != null) {
          clipFilters.add(audio.reverbPreset.ffmpegFilter!);
        }

        filterParts.add('[$inputIdx:a]${clipFilters.join(',')}[$label];');
        audioLabels.add('[$label]');

        inputIdx++;
        audioCounter++;
      }
    }

    String finalAudioHead = 'out_a';
    final settings = project.settings;

    if (audioLabels.isNotEmpty) {
      String mixedLabel = 'a_mixed';
      if (audioLabels.length == 1) {
        mixedLabel = audioLabels.first.replaceAll(RegExp(r'[\[\]]'), '');
      } else {
        filterParts.add(
            '${audioLabels.join('')}amix=inputs=${audioLabels.length}:duration=longest:dropout_transition=2[$mixedLabel];');
      }

      final audioFilters = <String>[];
      final masterVol =
          settings.isMasterMuted ? 0.0 : settings.masterVolume.clamp(0.0, 2.0);
      audioFilters.add('volume=$masterVol');

      if (settings.audioFadeInDuration > 0) {
        audioFilters.add('afade=t=in:ss=0:d=${settings.audioFadeInDuration}');
      }

      final totalSec = project.totalDurationMs / 1000.0;
      if (settings.audioFadeOutDuration > 0 && totalSec > 0) {
        final fadeOutStart =
            (totalSec - settings.audioFadeOutDuration).clamp(0.0, totalSec);
        audioFilters.add(
            'afade=t=out:st=${fadeOutStart.toStringAsFixed(3)}:d=${settings.audioFadeOutDuration}');
      }

      filterParts.add('[$mixedLabel]${audioFilters.join(',')}[$finalAudioHead];');
    } else {
      args.addAll([
        '-f',
        'lavfi',
        '-i',
        'anullsrc=channel_layout=stereo:sample_rate=44100',
      ]);
      final silenceLabel = 'a_silence';
      final totalSec = (project.totalDurationMs / 1000.0).toStringAsFixed(3);
      filterParts.add('[$inputIdx:a]atrim=0:$totalSec[$silenceLabel];');
      finalAudioHead = silenceLabel;
      inputIdx++;
    }

    return FfmpegAudioResult(
      audioLabels: audioLabels,
      finalAudioHead: finalAudioHead,
      nextInputIdx: inputIdx,
    );
  }
}
