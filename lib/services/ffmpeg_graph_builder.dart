import 'dart:io';
import 'dart:math';
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
    // 1. PRIMARY VIDEO CLIPS (Normalized with fps & yuv420p for xfade)
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
          '[$inputIdx:v]scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=$fps,format=yuv420p[$label];');
      primaryVideoLabels.add('[$label]');
      inputIdx++;
    }

    // Chained xfade or concat for primary clips
    String currentVideoHead = 'base_v';
    if (primaryVideoLabels.isEmpty) {
      final hex = _colorToHex(0xFF000000);
      args.addAll([
        '-f',
        'lavfi',
        '-i',
        'color=c=$hex:s=${width}x$height:d=1.0',
      ]);
      filterParts
          .add('[$inputIdx:v]fps=$fps,format=yuv420p[$currentVideoHead];');
      inputIdx++;
    } else if (primaryVideoLabels.length == 1) {
      currentVideoHead =
          primaryVideoLabels.first.replaceAll(RegExp(r'[\[\]]'), '');
    } else {
      final hasAnyTransition = primaryClips
          .skip(1)
          .any((c) => c.transition != TransitionType.none);

      if (!hasAnyTransition) {
        filterParts.add(
            '${primaryVideoLabels.join('')}concat=n=${primaryVideoLabels.length}:v=1:a=0[$currentVideoHead];');
      } else {
        String prevHead =
            primaryVideoLabels[0].replaceAll(RegExp(r'[\[\]]'), '');
        double accumulatedDurationSec = primaryClips[0].durationMs / 1000.0;

        for (int i = 1; i < primaryClips.length; i++) {
          final clip = primaryClips[i];
          final nextLabel = primaryVideoLabels[i];
          final nextDurSec = clip.durationMs / 1000.0;
          final stepHead =
              i == primaryClips.length - 1 ? currentVideoHead : 'v_step_$i';

          if (clip.transition != TransitionType.none) {
            final transName = switch (clip.transition) {
              TransitionType.fade => 'fade',
              TransitionType.wipeLeft => 'wipeleft',
              TransitionType.slideUp => 'slideup',
              TransitionType.zoom => 'zoomin',
              TransitionType.none => 'fade',
            };

            final maxTrans = (clip.transitionDurationMs / 1000.0)
                .clamp(0.1, min(accumulatedDurationSec, nextDurSec) * 0.8);
            final offset = max(0.0, accumulatedDurationSec - maxTrans);
            final durStr = maxTrans.toStringAsFixed(3);
            final offsetStr = offset.toStringAsFixed(3);

            filterParts.add(
                '[$prevHead]$nextLabel xfade=transition=$transName:duration=$durStr:offset=$offsetStr[$stepHead];');
            accumulatedDurationSec = offset + nextDurSec;
          } else {
            filterParts
                .add('[$prevHead]$nextLabel concat=n=2:v=1:a=0[$stepHead];');
            accumulatedDurationSec += nextDurSec;
          }
          prevHead = stepHead;
        }
      }
    }

    // -------------------------------------------------------------
    // 2. SECONDARY OVERLAY LAYERS (Video, Image, Sticker, Color)
    // -------------------------------------------------------------
    int overlayCounter = 0;
    for (final layer in secondaryClips) {
      if (layer.type == ClipType.video ||
          layer.type == ClipType.image ||
          layer.type == ClipType.sticker ||
          layer.type == ClipType.color) {
        final durSec = (layer.durationMs / 1000.0).toStringAsFixed(3);
        bool hasValidSource = false;

        if (layer.type == ClipType.color || layer.assetPath == null) {
          final hex = _colorToHex(layer.colorValue);
          final colW = (width * layer.scale).round().clamp(16, width * 2);
          final colH = (height * layer.scale).round().clamp(16, height * 2);
          args.addAll([
            '-f',
            'lavfi',
            '-i',
            'color=c=$hex:s=${colW}x$colH:d=$durSec',
          ]);
          hasValidSource = true;
        } else if (File(layer.assetPath!).existsSync()) {
          if (layer.type == ClipType.image || layer.type == ClipType.sticker) {
            args.addAll(['-loop', '1', '-t', durSec, '-i', layer.assetPath!]);
          } else {
            final inSec = (layer.sourceInMs / 1000.0).toStringAsFixed(3);
            args.addAll(['-ss', inSec, '-t', durSec, '-i', layer.assetPath!]);
          }
          hasValidSource = true;
        }

        if (hasValidSource) {
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

          // Opacity & In/Out Fade Animations
          final totalLayerSec = layer.durationMs / 1000.0;
          final inDurSec = (layer.inDurationMs / 1000.0)
              .clamp(0.1, max(0.1, totalLayerSec * 0.45));
          final outDurSec = (layer.outDurationMs / 1000.0)
              .clamp(0.1, max(0.1, totalLayerSec * 0.45));

          final hasInFade = (layer.inAnimation == InAnimationType.fadeIn ||
                  layer.inAnimation == InAnimationType.pop ||
                  layer.inAnimation == InAnimationType.scaleUp) &&
              layer.inDurationMs > 0;
          final hasOutFade = (layer.outAnimation == OutAnimationType.fadeOut ||
                  layer.outAnimation == OutAnimationType.popDown ||
                  layer.outAnimation == OutAnimationType.scaleDown) &&
              layer.outDurationMs > 0;

          if (hasInFade || hasOutFade || layer.opacity < 1.0) {
            filterChain.add('format=rgba');
            if (layer.opacity < 1.0) {
              filterChain.add('colorchannelmixer=aa=${layer.opacity}');
            }
            if (hasInFade) {
              filterChain.add(
                  'fade=t=in:st=0:d=${inDurSec.toStringAsFixed(3)}:alpha=1');
            }
            if (hasOutFade) {
              final outStartSec =
                  max(0.0, totalLayerSec - outDurSec).toStringAsFixed(3);
              filterChain.add(
                  'fade=t=out:st=$outStartSec:d=${outDurSec.toStringAsFixed(3)}:alpha=1');
            }
          }

          filterParts.add(
              '[$inputIdx:v]${filterChain.join(',')}[$rawLayerLabel];');

          // Overlay positioning, timing & motion in-animations
          final nextHead = 'v_overlay_$overlayCounter';
          final startSec = (layer.startMs / 1000.0).toStringAsFixed(3);
          final endSec = (layer.endMs / 1000.0).toStringAsFixed(3);
          final inEndSec =
              ((layer.startMs + layer.inDurationMs) / 1000.0).toStringAsFixed(3);

          final baseX = '(W-w)/2+(${layer.offsetX.toStringAsFixed(3)}*(W/2))';
          final baseY = '(H-h)/2+(${layer.offsetY.toStringAsFixed(3)}*(H/2))';

          String posX = baseX;
          String posY = baseY;

          if (layer.inAnimation == InAnimationType.slideRight &&
              layer.inDurationMs > 0) {
            posX =
                'if(lte(t,$inEndSec),$baseX-W*(1-(t-$startSec)/${inDurSec.toStringAsFixed(3)}),$baseX)';
          } else if (layer.inAnimation == InAnimationType.slideLeft &&
              layer.inDurationMs > 0) {
            posX =
                'if(lte(t,$inEndSec),$baseX+W*(1-(t-$startSec)/${inDurSec.toStringAsFixed(3)}),$baseX)';
          } else if (layer.inAnimation == InAnimationType.slideUp &&
              layer.inDurationMs > 0) {
            posY =
                'if(lte(t,$inEndSec),$baseY+H*(1-(t-$startSec)/${inDurSec.toStringAsFixed(3)}),$baseY)';
          } else if (layer.inAnimation == InAnimationType.slideDown &&
              layer.inDurationMs > 0) {
            posY =
                'if(lte(t,$inEndSec),$baseY-H*(1-(t-$startSec)/${inDurSec.toStringAsFixed(3)}),$baseY)';
          }

          filterParts.add(
              '[$currentVideoHead][$rawLayerLabel]overlay=x=\'$posX\':y=\'$posY\':enable=\'between(t,$startSec,$endSec)\'[$nextHead];');
          currentVideoHead = nextHead;

          inputIdx++;
          overlayCounter++;
        }
      }
    }

    // -------------------------------------------------------------
    // 3. TEXT CLIPS (drawtext with alpha fade in/out)
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

        if (textClip.inAnimation == InAnimationType.fadeIn &&
            textClip.inDurationMs > 0) {
          final inDur = (textClip.inDurationMs / 1000.0).toStringAsFixed(3);
          drawtextParams
              .add("alpha='if(lt(t,$startSec+$inDur),(t-$startSec)/$inDur,1)'");
        }

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
