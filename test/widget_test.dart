import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyreon_studio/main.dart';
import 'package:vyreon_studio/models/aspect_ratio.dart';
import 'package:vyreon_studio/models/project.dart';
import 'package:vyreon_studio/models/subtitle_entry.dart';
import 'package:vyreon_studio/models/timeline_clip.dart';
import 'package:vyreon_studio/screens/editor_screen.dart';
import 'package:vyreon_studio/services/audio_recording_service.dart';
import 'package:vyreon_studio/services/audio_waveform_service.dart';
import 'package:vyreon_studio/services/ffmpeg_graph_builder.dart';
import 'package:vyreon_studio/services/project_package_service.dart';
import 'package:vyreon_studio/services/project_storage_service.dart';
import 'package:vyreon_studio/services/rust_engine_service.dart';
import 'package:vyreon_studio/services/srt_service.dart';
import 'package:vyreon_studio/services/video_thumbnail_service.dart';
import 'package:vyreon_studio/state/editor_controller.dart';
import 'package:vyreon_studio/widgets/timeline/timeline_playhead_widget.dart';

void main() {
  testWidgets('Vyreon Studio smoke test', (WidgetTester tester) async {
    // Pre-seed storage cache in async context so build is synchronous
    await tester.runAsync(() async {
      await ProjectStorageService.instance.loadProjects();
    });

    await tester.pumpWidget(const VyreonStudioApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Dashboard displays branding
    expect(find.text('VYREON STUDIO'), findsOneWidget);
    expect(find.text('Create New Project'), findsOneWidget);

    // Responsive Mobile Portrait test
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    await tester.pump();
    expect(find.text('VYREON STUDIO'), findsOneWidget);

    // Responsive Desktop test
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    await tester.pump();
    expect(find.text('VYREON STUDIO'), findsOneWidget);

    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('EditorScreen responsive layout test', (WidgetTester tester) async {
    final sampleProject = Project.createSample('Responsive Test', ProjectAspectRatio.ratio16x9);

    // 1. Mobile Portrait (390x844)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(MaterialApp(home: EditorScreen(project: sampleProject)));
    await tester.pump();
    expect(find.text('Responsive Test'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);

    // 2. Mobile Landscape (844x390)
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(MaterialApp(home: EditorScreen(project: sampleProject)));
    await tester.pump();
    expect(find.byIcon(Icons.file_upload_outlined), findsWidgets);

    // 3. Desktop (1920x1080)
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(MaterialApp(home: EditorScreen(project: sampleProject)));
    await tester.pump();
    expect(find.byIcon(Icons.file_upload_outlined), findsWidgets);

    // Verify playhead widget is present and draggable
    final playheadFinder = find.byType(TimelinePlayheadWidget);
    expect(playheadFinder, findsOneWidget);
    await tester.drag(playheadFinder, const Offset(60, 0));
    await tester.pump();

    addTearDown(tester.view.resetPhysicalSize);
  });

  test('EditorController timeline operations test', () async {
    final project = Project.createSample('Test Project', ProjectAspectRatio.ratio16x9);
    final controller = EditorController(project);

    expect(controller.project.clips.isNotEmpty, true);
    expect(controller.playheadMs, 0);

    // Seek test
    controller.seekTo(2500);
    expect(controller.playheadMs, 2500);

    // Play/Pause test
    controller.play();
    expect(controller.isPlaying, true);
    controller.pause();
    expect(controller.isPlaying, false);

    // Split test
    final firstClipId = controller.project.primaryClips.first.id;
    controller.splitClipAtPlayhead(firstClipId);
    expect(controller.project.clips.length, project.clips.length + 1);

    // Undo test
    expect(controller.canUndo, true);
    controller.undo();
    expect(controller.project.clips.length, project.clips.length);

    // Keyframe operations test
    final textClipId = controller.project.secondaryClips.first.id;
    controller.seekTo(controller.project.secondaryClips.first.startMs + 500);
    controller.toggleKeyframeAtPlayhead(textClipId);
    expect(controller.project.clips.firstWhere((c) => c.id == textClipId).keyframes.length, 1);

    // Speed curve interpolation test
    final clip = controller.project.primaryClips.first;
    expect(clip.getEffectiveSpeedAt(0.5), 1.0);
    final rampedClip = clip.copyWith(
      speedPoints: [
        const SpeedPoint(position: 0.0, speed: 1.0),
        const SpeedPoint(position: 0.5, speed: 0.3),
        const SpeedPoint(position: 1.0, speed: 2.0),
      ],
    );
    expect(rampedClip.getEffectiveSpeedAt(0.5), closeTo(0.3, 0.001));
    expect(rampedClip.getEffectiveSpeedAt(0.25) < 1.0, true);

    // Color grading & Vignette test
    final gradedClip = clip.copyWith(
      filter: ColorFilterPreset.tealAndOrange,
      isVignetteEnabled: true,
      vignetteIntensity: 0.75,
    );
    expect(gradedClip.filter, ColorFilterPreset.tealAndOrange);
    expect(gradedClip.isVignetteEnabled, true);
    expect(gradedClip.vignetteIntensity, 0.75);

    // Text styling test (Outline, Shadow, Glow)
    final textClip = controller.project.secondaryClips.first.copyWith(
      isTextOutlineEnabled: true,
      textOutlineColor: 0xFF000000,
      textOutlineWidth: 3.5,
      isTextShadowEnabled: true,
      isTextGlowEnabled: true,
      textGlowColor: 0xFFFFD700,
    );
    expect(textClip.isTextOutlineEnabled, true);
    expect(textClip.textOutlineWidth, 3.5);
    expect(textClip.isTextShadowEnabled, true);
    expect(textClip.isTextGlowEnabled, true);
    expect(textClip.textGlowColor, 0xFFFFD700);

    // Audio EQ & Voice Changer test
    final audioClip = controller.project.secondaryClips
        .firstWhere((c) => c.type == ClipType.audio)
        .copyWith(
          eqPreset: AudioEqPreset.bassBooster,
          voiceChanger: VoiceChangerPreset.chipmunk,
        );
    expect(audioClip.eqPreset, AudioEqPreset.bassBooster);
    expect(audioClip.eqPreset.bandGains.first, 6);
    expect(audioClip.voiceChanger, VoiceChangerPreset.chipmunk);
    expect(audioClip.voiceChanger.pitchSemitones, 6);

    // Audio Waveform test
    final waveformSamples = await AudioWaveformService().getWaveformSamples(
      clipId: audioClip.id,
      durationMs: audioClip.durationMs,
      targetSampleCount: 50,
    );
    expect(waveformSamples.length, 50);
    expect(waveformSamples.first, greaterThan(0.0));

    final clipWithWaveform = audioClip.copyWith(waveformSamples: waveformSamples);
    expect(clipWithWaveform.waveformSamples.isNotEmpty, true);

    // Pan & Zoom (Ken Burns) test
    final pzClip = clip.copyWith(
      panZoom: const PanZoomTransform(
        isEnabled: true,
        startScale: 1.0,
        endScale: 1.5,
        startOffsetX: 0.0,
        endOffsetX: 0.4,
      ),
    );
    expect(pzClip.panZoom.isEnabled, true);
    final midTransform = pzClip.panZoom.lerpAt(0.5);
    expect(midTransform.scale, closeTo(1.25, 0.01));
    expect(midTransform.offsetX, closeTo(0.2, 0.01));

    // Picture-in-Picture (PiP) Split Screen test
    controller.applyPipPreset(textClip.id, PipPreset.splitLeft);
    final pipClip = controller.project.clips.firstWhere((c) => c.id == textClip.id);
    expect(pipClip.pipPreset, PipPreset.splitLeft);
    expect(pipClip.scale, 0.5);
    expect(pipClip.offsetX, -0.5);

    // Multi-layer Drag & Drop / Reordering test
    final initialSecondaries = controller.project.secondaryClips;
    expect(initialSecondaries.length, greaterThanOrEqualTo(2));
    final firstSecondaryId = initialSecondaries.first.id;
    controller.bringToFront(firstSecondaryId);
    expect(controller.project.secondaryClips.last.id, firstSecondaryId);

    controller.sendToBack(firstSecondaryId);
    expect(controller.project.secondaryClips.first.id, firstSecondaryId);

    controller.reorderSecondaryClips(0, 2);
    expect(controller.project.secondaryClips[1].id, firstSecondaryId);

    // Video Thumbnail & Duration probe test
    final nonExistentThumb = await VideoThumbnailService().getThumbnailFile('non_existent.mp4');
    expect(nonExistentThumb, isNull);
    final nonExistentDuration = await VideoThumbnailService().probeDurationMs('non_existent.mp4');
    expect(nonExistentDuration, isNull);

    // Layer Animations test (In, Overall, Out)
    final animatedLayer = textClip.copyWith(
      inAnimation: InAnimationType.fadeIn,
      inDurationMs: 800,
      overallAnimation: OverallAnimationType.pulse,
      outAnimation: OutAnimationType.fadeOut,
      outDurationMs: 500,
    );
    expect(animatedLayer.inAnimation, InAnimationType.fadeIn);
    expect(animatedLayer.inDurationMs, 800);
    expect(animatedLayer.overallAnimation, OverallAnimationType.pulse);
    expect(animatedLayer.outAnimation, OutAnimationType.fadeOut);
    expect(animatedLayer.outDurationMs, 500);

    // Rust Engine Service test
    final rust = RustEngineService.instance;
    expect(rust.version.isNotEmpty, true);
    if (rust.isAvailable) {
      expect(rust.version, contains('RustCore'));
      final lerp = rust.lerpTransform(
        t: 0.5,
        startScale: 1.0,
        endScale: 2.0,
        startX: 0.0,
        endX: 10.0,
        startY: -4.0,
        endY: 4.0,
      );
      expect(lerp, isNotNull);
      expect(lerp!.scale, closeTo(1.5, 0.01));
      expect(lerp.offsetX, closeTo(5.0, 0.01));

      final alpha = rust.chromaKeyAlpha(
        r: 0,
        g: 255,
        b: 0,
        keyR: 0,
        keyG: 255,
        keyB: 0,
        threshold: 0.35,
        smoothness: 0.1,
      );
      expect(alpha, 0);
    }

    // Volume Envelope & Audio Ducking test
    final envelopedAudio = audioClip.copyWith(
      isDuckingEnabled: true,
      duckingLevel: 0.2,
      volumeEnvelope: [
        const VolumePoint(timeMs: 0, volume: 1.0),
        const VolumePoint(timeMs: 2000, volume: 0.5),
        const VolumePoint(timeMs: 4000, volume: 1.2),
      ],
    );
    expect(envelopedAudio.isDuckingEnabled, true);
    expect(envelopedAudio.duckingLevel, 0.2);
    expect(envelopedAudio.getEffectiveVolumeAt(1000), closeTo(0.75, 0.01));
    expect(envelopedAudio.getEffectiveVolumeAt(1000, isDucked: true), closeTo(0.15, 0.01));

    // Freeze Frame & Snapshot Layer test
    final countBefore = controller.project.clips.length;
    controller.seekTo(1500);
    controller.insertFreezeFrameAtPlayhead(durationMs: 2500);
    expect(controller.project.clips.length, greaterThan(countBefore));
    expect(controller.project.primaryClips.any((c) => c.name.contains('Freeze Frame')), true);

    final secondariesBefore = controller.project.secondaryClips.length;
    controller.addSnapshotAsLayer(durationMs: 3500);
    expect(controller.project.secondaryClips.length, secondariesBefore + 1);
    expect(controller.project.secondaryClips.last.name, 'Snapshot Layer');

    // Cropping & Shape Mask test
    final maskedClip = clip.copyWith(
      cropMask: const ClipCropMask(
        isMaskEnabled: true,
        maskShape: MaskShape.circle,
        cropLeft: 0.1,
        cropRight: 0.1,
      ),
    );
    expect(maskedClip.cropMask.isMaskEnabled, true);
    expect(maskedClip.cropMask.maskShape, MaskShape.circle);
    final path = maskedClip.cropMask.getClipPath(const Size(100, 100));
    expect(path.getBounds().width, closeTo(80, 0.5));

    // Extract Audio from video clip test
    final testVideoClip = TimelineClip(
      id: 'test_vid_extract',
      name: 'Sample Vid',
      type: ClipType.video,
      startMs: 0,
      durationMs: 5000,
      sourceDurationMs: 5000,
      isPrimary: true,
    );
    controller.addPrimaryClip(testVideoClip);
    final extractedAudio = await controller.extractAudioFromClip(testVideoClip.id);
    expect(extractedAudio, isNotNull);
    expect(extractedAudio!.type, ClipType.audio);
    final actualVideo = controller.project.clips.firstWhere((c) => c.id == testVideoClip.id);
    expect(extractedAudio.startMs, actualVideo.startMs);
    expect(extractedAudio.durationMs, actualVideo.durationMs);
    expect(actualVideo.isMuted, true);

    // Reverse Video Clip test
    final reversed = await controller.reverseClip(testVideoClip.id);
    expect(reversed, true);
    final reversedClip = controller.project.clips.firstWhere((c) => c.id == testVideoClip.id);
    expect(reversedClip.name, contains('(Reversed)'));

    // Audio Reverb Preset test
    final reverbAudio = extractedAudio.copyWith(
      reverbPreset: AudioReverbPreset.cathedral,
    );
    expect(reverbAudio.reverbPreset, AudioReverbPreset.cathedral);
    expect(reverbAudio.reverbPreset.ffmpegFilter, contains('aecho'));

    // Subtitle & SRT Parser / Exporter test
    const rawSrt = '''1
00:00:01,000 --> 00:00:04,500
Hello Vyreon!

2
00:00:05,000 --> 00:00:08,200
Second subtitle line''';

    final parsedSubtitles = SrtService.parseSrt(rawSrt);
    expect(parsedSubtitles.length, 2);
    expect(parsedSubtitles.first.text, 'Hello Vyreon!');
    expect(parsedSubtitles.first.startMs, 1000);
    expect(parsedSubtitles.first.endMs, 4500);

    final exportedSrt = SrtService.exportSrt(parsedSubtitles);
    expect(exportedSrt, contains('Hello Vyreon!'));
    expect(exportedSrt, contains('00:00:01,000 --> 00:00:04,500'));

    controller.importSrt(rawSrt);
    expect(controller.project.subtitles.length, 2);

    controller.addSubtitle(const SubtitleEntry(
      index: 3,
      startMs: 9000,
      endMs: 12000,
      text: 'Third line',
    ));
    expect(controller.project.subtitles.length, 3);

    controller.deleteSubtitle(3);
    expect(controller.project.subtitles.length, 2);

    // Audio Master Mixer settings test
    expect(controller.project.settings.masterVolume, 1.0);
    expect(controller.project.settings.isMasterMuted, false);

    controller.updateSettings(controller.project.settings.copyWith(
      masterVolume: 1.5,
      isMasterMuted: true,
      audioFadeInDuration: 2.0,
      audioFadeOutDuration: 3.0,
      customExportDirectory: '/home/user/CustomVideos',
    ));
    expect(controller.project.settings.masterVolume, 1.5);
    expect(controller.project.settings.isMasterMuted, true);
    expect(controller.project.settings.audioFadeInDuration, 2.0);
    expect(controller.project.settings.audioFadeOutDuration, 3.0);
    expect(controller.project.settings.customExportDirectory, '/home/user/CustomVideos');

    // Advanced Typography & Text Box styling test
    final styledTextClip = textClip.copyWith(
      textAlign: 'left',
      letterSpacing: 2.5,
      lineSpacing: 1.5,
      isTextBackgroundEnabled: true,
      textBackgroundColor: 0xCC000000,
      textBackgroundCornerRadius: 8.0,
      textBackgroundPadding: 12.0,
    );
    expect(styledTextClip.textAlign, 'left');
    expect(styledTextClip.letterSpacing, 2.5);
    expect(styledTextClip.lineSpacing, 1.5);
    expect(styledTextClip.isTextBackgroundEnabled, true);
    expect(styledTextClip.textBackgroundColor, 0xCC000000);
    expect(styledTextClip.textBackgroundCornerRadius, 8.0);
    expect(styledTextClip.textBackgroundPadding, 12.0);

    // Project Archive Packager (.vyreon bundle) test
    final exportResult = await ProjectPackageService.instance
        .exportBundle(controller.project);
    expect(exportResult.success, true);
    expect(exportResult.filePath, isNotNull);
    expect(exportResult.filePath, endsWith('.vyreon'));

    final importResult = await ProjectPackageService.instance
        .importBundle(exportResult.filePath!);
    expect(importResult.success, true);
    expect(importResult.project, isNotNull);
    expect(importResult.project!.name, contains('(Imported)'));
    expect(importResult.project!.clips.length, controller.project.clips.length);

    // Eyedropper Chroma Key Color Picker test
    controller.selectClip(textClip.id);
    controller.startEyedropper();
    expect(controller.isEyedropperActive, true);

    controller.eyedropperColor = 0xFF00FF7F;
    expect(controller.eyedropperColor, 0xFF00FF7F);

    controller.applyEyedropperColor();
    expect(controller.isEyedropperActive, false);
    final chromaClip = controller.project.clips.firstWhere((c) => c.id == textClip.id);
    expect(chromaClip.chromaKeyColor, 0xFF00FF7F);

    controller.startEyedropper();
    controller.cancelEyedropper();
    expect(controller.isEyedropperActive, false);

    // Audio Beat Detection & Snap-to-Beat test
    controller.seekTo(0, snapToBeat: false);
    final testBeatsAudio = TimelineClip(
      id: 'test_beats_audio',
      name: 'Rhythm Song',
      type: ClipType.audio,
      startMs: 0,
      durationMs: 8000,
      sourceDurationMs: 8000,
      waveformSamples: [0.1, 0.2, 0.95, 0.3, 0.1, 0.9, 0.2, 0.1],
    );
    controller.addSecondaryClip(testBeatsAudio);

    controller.detectBeatsForClip(testBeatsAudio.id);
    final clipWithBeats = controller.project.clips.firstWhere((c) => c.id == testBeatsAudio.id);
    expect(clipWithBeats.beatMarkers.isNotEmpty, true);

    final firstBeat = clipWithBeats.beatMarkers.first;
    // Scrub within snap threshold (40ms away from first beat)
    controller.seekTo(firstBeat + 40, snapToBeat: true);
    expect(controller.playheadMs, firstBeat); // Snapped!

    // Toggle manual beat marker at playhead
    final previousBeatCount = clipWithBeats.beatMarkers.length;
    controller.seekTo(4500, snapToBeat: false);
    controller.toggleBeatMarkerAtPlayhead(testBeatsAudio.id);
    final clipAfterToggle = controller.project.clips.firstWhere((c) => c.id == testBeatsAudio.id);
    expect(clipAfterToggle.beatMarkers.length, previousBeatCount + 1);

    // Full Multi-Layer FFmpeg Composite Exporter test
    final renderGraph = FfmpegGraphBuilder.buildGraph(
      project: controller.project,
      width: 1920,
      height: 1080,
      fps: 30,
    );
    expect(renderGraph.inputArgs.isNotEmpty, true);
    expect(renderGraph.filterComplex.contains('scale='), true);
    expect(renderGraph.filterComplex.contains('drawtext'), true);
    expect(renderGraph.filterComplex.contains('subtitles'), true);
    expect(renderGraph.videoMap.isNotEmpty, true);
    expect(renderGraph.audioMap.isNotEmpty, true);

    // Audio Recording Service test
    expect(AudioRecordingService.instance.isRecording, false);
    final hasPerm = await AudioRecordingService.instance.hasPermission();
    expect(hasPerm, isA<bool>());

    // Audio Denoise & Enhancer test
    final audioWithDenoise = testBeatsAudio.copyWith(
      denoisePreset: AudioDenoisePreset.voiceClarity,
      enhancePreset: AudioEnhancePreset.warmVocal,
    );
    expect(audioWithDenoise.denoisePreset, AudioDenoisePreset.voiceClarity);
    expect(audioWithDenoise.enhancePreset, AudioEnhancePreset.warmVocal);

    // Serialization roundtrip
    final jsonClip = audioWithDenoise.toJson();
    final restoredClip = TimelineClip.fromJson(jsonClip);
    expect(restoredClip.denoisePreset, AudioDenoisePreset.voiceClarity);
    expect(restoredClip.enhancePreset, AudioEnhancePreset.warmVocal);

    controller.updateClip(audioWithDenoise);

    // Rust Engine Color Grading & 3D LUT Test
    final samplePixels = Uint8List.fromList([100, 100, 100, 255]);
    final graded = RustEngineService.instance.colorGradeRgba(
      samplePixels,
      brightness: 0.2,
      contrast: 0.1,
      saturation: 1.2,
    );
    if (RustEngineService.instance.isAvailable) {
      expect(graded, isNotNull);
      expect(graded![0] > 100, true);

      // Rust Engine Real-time Audio DSP Test
      final audioSamples = Int16List.fromList([10, 20, 10000]);
      final processedAudio = RustEngineService.instance.processAudioPcm16(
        audioSamples,
        volume: 1.5,
        noiseGateThreshold: 0.05,
      );
      expect(processedAudio, isNotNull);
      expect(processedAudio!.length, 3);

      // Rust Engine Bézier Speed Curve Test
      final bezierVal = RustEngineService.instance.evaluateBezier(0.5);
      expect(bezierVal >= 0.0 && bezierVal <= 1.0, true);

      final speedCurve = RustEngineService.instance.evaluateSpeedCurveBatch(
        Float32List.fromList([0.0, 0.5, 1.0]),
      );
      expect(speedCurve, isNotNull);
      expect(speedCurve!.length, 3);
    }

    controller.dispose();
  });
}
