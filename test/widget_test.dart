import 'package:flutter_test/flutter_test.dart';
import 'package:vyreon_studio/main.dart';
import 'package:vyreon_studio/models/aspect_ratio.dart';
import 'package:vyreon_studio/models/project.dart';
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
  });

  test('EditorController timeline operations test', () {
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

    controller.dispose();
  });
}
