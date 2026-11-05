import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyreon_studio/main.dart';
import 'package:vyreon_studio/models/aspect_ratio.dart';
import 'package:vyreon_studio/models/project.dart';
import 'package:vyreon_studio/models/timeline_clip.dart';
import 'package:vyreon_studio/screens/editor_screen.dart';
import 'package:vyreon_studio/services/audio_waveform_service.dart';
import 'package:vyreon_studio/services/rust_engine_service.dart';
import 'package:vyreon_studio/services/video_thumbnail_service.dart';
import 'package:vyreon_studio/services/project_storage_service.dart';
import 'package:vyreon_studio/state/editor_controller.dart';

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

    controller.dispose();
  });
}
