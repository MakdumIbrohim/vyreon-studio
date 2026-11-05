import 'dart:io';
import '../models/clip_types.dart';
import '../models/project.dart';
import '../models/timeline_clip.dart';
import 'ffmpeg_audio_pipeline.dart';
import 'srt_service.dart';

class FfmpegGraphResult {
  final List<String> inputArgs;
  final String filterComplex;
  final String videoMap;
  final String audioMap;
  final List<File> tempFilesToClean;

  const FfmpegGraphResult({
    required this.inputArgs,
    required this.filterComplex,
    required this.videoMap,
    required this.audioMap,
    this.tempFilesToClean = const [],
  });
}

class FfmpegGraphBuilder {
  static String _colorToHex(int colorVal) {
    final r = (colorVal >> 16) & 0xFF;
    final g = (colorVal >> 8) & 0xFF;
    final b = colorVal & 0xFF;
    return '0x${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }

  static String _escapeText(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll(':', r'\:')
        .replaceAll('%', r'\%');
  }

  static FfmpegGraphResult buildGraph({
    required Project project,
    required int width,
    required int height,
    required int fps,
  }) {
    final args = <String>['-y'];
    final filterParts = <String>[];
    final tempFiles = <File>[];
    int inputIdx = 0;

    final primaryClips = project.primaryClips;
    final secondaryClips = project.secondaryClips;

    // -------------------------------------------------------------
    // 1. PRIMARY VIDEO CLIPS
    // -------------------------------------------------------------
    final primaryVideoLabels = <String>[];

    for (final clip in primaryClips) {
      final durSec = (clip.durationMs / 1000.0).toStringAsFixed(3);

      if (clip.assetPath != null && File(clip.assetPath!).existsSync()) {
        if (clip.type == ClipType.image) {
          args.addAll(['-loop', '1', '-t', durSec, '-i', clip.assetPath!]);
        } else {
          final inSec = (clip.sourceInMs / 1000.0).toStringAsFixed(3);
          args.addAll(['-ss', inSec, '-t', durSec, '-i', clip.assetPath!]);
        }
      } else {
        final hex = _colorToHex(clip.colorValue);
        args.addAll([
          '-f',
          'lavfi',
          '-i',
          'color=c=$hex:s=${width}x$height:d=$durSec',
        ]);
      }

      final label = 'v_prim_$inputIdx';
      filterParts.add(
          '[$inputIdx:v]scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1[$label];');
      primaryVideoLabels.add('[$label]');
      inputIdx++;
    }

    // Concatenate primary clips into base video stream
    String currentVideoHead = 'base_v';
    if (primaryVideoLabels.length == 1) {
      currentVideoHead = primaryVideoLabels.first.replaceAll(RegExp(r'[\[\]]'), '');
    } else {
      filterParts.add(
          '${primaryVideoLabels.join('')}concat=n=${primaryVideoLabels.length}:v=1:a=0[$currentVideoHead];');
    }

    // -------------------------------------------------------------
    // 2. SECONDARY OVERLAY LAYERS (Video, Image, Sticker)
    // -------------------------------------------------------------
    int overlayCounter = 0;
    for (final layer in secondaryClips) {
      if (layer.type == ClipType.video ||
          layer.type == ClipType.image ||
          layer.type == ClipType.sticker) {
        if (layer.assetPath != null && File(layer.assetPath!).existsSync()) {
          final durSec = (layer.durationMs / 1000.0).toStringAsFixed(3);
          if (layer.type == ClipType.image || layer.type == ClipType.sticker) {
            args.addAll(['-loop', '1', '-t', durSec, '-i', layer.assetPath!]);
          } else {
            final inSec = (layer.sourceInMs / 1000.0).toStringAsFixed(3);
            args.addAll(['-ss', inSec, '-t', durSec, '-i', layer.assetPath!]);
          }

          final rawLayerLabel = 'layer_raw_$overlayCounter';
          final filterChain = <String>[];

          // Scale
          final scaleFactor = layer.scale.clamp(0.1, 4.0);
          filterChain.add('scale=iw*$scaleFactor:ih*$scaleFactor');

          // Chroma Key
          if (layer.isChromaKeyEnabled) {
            final keyHex = _colorToHex(layer.chromaKeyColor);
            filterChain.add(
                'colorkey=$keyHex:${layer.chromaThreshold}:${layer.chromaSmoothness}');
          }

          // Opacity
          if (layer.opacity < 1.0) {
            filterChain.add('format=rgba,colorchannelmixer=aa=${layer.opacity}');
          }

          filterParts.add(
              '[$inputIdx:v]${filterChain.join(',')}[$rawLayerLabel];');

          // Overlay onto current video head with positioning & timing
          final nextHead = 'v_overlay_$overlayCounter';
          final startSec = (layer.startMs / 1000.0).toStringAsFixed(3);
          final endSec = (layer.endMs / 1000.0).toStringAsFixed(3);

          final posX =
              '(W-w)/2+(${layer.offsetX.toStringAsFixed(3)}*(W/2))';
          final posY =
              '(H-h)/2+(${layer.offsetY.toStringAsFixed(3)}*(H/2))';

          filterParts.add(
              '[$currentVideoHead][$rawLayerLabel]overlay=x=\'$posX\':y=\'$posY\':enable=\'between(t,$startSec,$endSec)\'[$nextHead];');
          currentVideoHead = nextHead;

          inputIdx++;
          overlayCounter++;
        }
      }
    }

    // -------------------------------------------------------------
    // 3. TEXT CLIPS (drawtext)
    // -------------------------------------------------------------
    int textCounter = 0;
    for (final textClip in secondaryClips) {
      if (textClip.type == ClipType.text) {
        final nextHead = 'v_text_$textCounter';
        final startSec = (textClip.startMs / 1000.0).toStringAsFixed(3);
        final endSec = (textClip.endMs / 1000.0).toStringAsFixed(3);

        final escaped = _escapeText(textClip.textContent);
        final fontSize =
            (textClip.fontSize * (height / 720.0)).round().clamp(12, 120);
        final fontColor = _colorToHex(textClip.colorValue);

        final posX =
            '(w-text_w)/2+(${textClip.offsetX.toStringAsFixed(3)}*(w/2))';
        final posY =
            '(h-text_h)/2+(${textClip.offsetY.toStringAsFixed(3)}*(h/2))';

        final drawtextParams = <String>[
          "text='$escaped'",
          'fontsize=$fontSize',
          'fontcolor=$fontColor',
          "x='$posX'",
          "y='$posY'",
          "enable='between(t,$startSec,$endSec)'",
        ];

        if (textClip.isTextOutlineEnabled) {
          drawtextParams.add(
              'borderw=${textClip.textOutlineWidth.round().clamp(1, 10)}');
          drawtextParams
              .add('bordercolor=${_colorToHex(textClip.textOutlineColor)}');
        }

        if (textClip.isTextBackgroundEnabled) {
          drawtextParams.add('box=1');
          drawtextParams
              .add('boxcolor=${_colorToHex(textClip.textBackgroundColor)}@0.6');
          drawtextParams.add(
              'boxborderw=${textClip.textBackgroundPadding.round().clamp(2, 20)}');
        }

        filterParts.add(
            '[$currentVideoHead]drawtext=${drawtextParams.join(':')}[$nextHead];');
        currentVideoHead = nextHead;
        textCounter++;
      }
    }

    // -------------------------------------------------------------
    // 4. SUBTITLES (.SRT Burn-In)
    // -------------------------------------------------------------
    if (project.subtitles.isNotEmpty) {
      final srtContent = SrtService.exportSrt(project.subtitles);
      final tempSrt = File(
          '${Directory.systemTemp.path}/vyreon_sub_${DateTime.now().millisecondsSinceEpoch}.srt');
      tempSrt.writeAsStringSync(srtContent, flush: true);
      tempFiles.add(tempSrt);

      final nextHead = 'v_sub_burn';
      final cleanPath = tempSrt.path.replaceAll(r'\', '/');
      filterParts.add(
          '[$currentVideoHead]subtitles=\'$cleanPath\':force_style=\'FontSize=18,PrimaryColour=&H00FFFFFF,BorderStyle=3\'[$nextHead];');
      currentVideoHead = nextHead;
    }

    // -------------------------------------------------------------
    // 5. AUDIO TRACKS & MASTER MIXER
    // -------------------------------------------------------------
    final audioResult = FfmpegAudioPipeline.build(
      project: project,
      args: args,
      filterParts: filterParts,
      startInputIdx: inputIdx,
    );

    return FfmpegGraphResult(
      inputArgs: args,
      filterComplex: filterParts.join(''),
      videoMap: currentVideoHead,
      audioMap: audioResult.finalAudioHead,
      tempFilesToClean: tempFiles,
    );
  }
}
