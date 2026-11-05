import '../../models/timeline_clip.dart';
import '../editor_controller_base.dart';

mixin EditorLayerOpsMixin on EditorControllerBase {
  void bringToFront(String clipId) {
    final clip = project.clips.firstWhere((c) => c.id == clipId);
    if (clip.isPrimary) return;
    pushUndo();
    final nonSelected = project.clips.where((c) => c.id != clipId).toList();
    project = project.copyWith(
      clips: [...nonSelected, clip],
      modifiedAt: DateTime.now(),
    );
    notifyListeners();
    autoSave();
  }

  void sendToBack(String clipId) {
    final clip = project.clips.firstWhere((c) => c.id == clipId);
    if (clip.isPrimary) return;
    pushUndo();
    final primaries = project.primaryClips;
    final otherSecondaries =
        project.secondaryClips.where((c) => c.id != clipId).toList();
    project = project.copyWith(
      clips: [...primaries, clip, ...otherSecondaries],
      modifiedAt: DateTime.now(),
    );
    notifyListeners();
    autoSave();
  }

  void reorderSecondaryClips(int oldIndex, int newIndex) {
    final secondaries = List<TimelineClip>.from(project.secondaryClips);
    if (oldIndex < 0 || oldIndex >= secondaries.length) return;
    if (newIndex > secondaries.length) newIndex = secondaries.length;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    pushUndo();
    final item = secondaries.removeAt(oldIndex);
    secondaries.insert(newIndex, item);
    project = project.copyWith(
      clips: [...project.primaryClips, ...secondaries],
      modifiedAt: DateTime.now(),
    );
    notifyListeners();
    autoSave();
  }

  void applyPipPreset(String clipId, PipPreset preset) {
    final clip = project.clips.firstWhere((c) => c.id == clipId);
    pushUndo();
    final updated = clip.copyWith(
      pipPreset: preset,
      scale: preset == PipPreset.none ? clip.scale : preset.defaultScale,
      offsetX: preset == PipPreset.none ? clip.offsetX : preset.defaultOffsetX,
      offsetY: preset == PipPreset.none ? clip.offsetY : preset.defaultOffsetY,
    );
    // Call updateClip
    final index = project.clips.indexWhere((c) => c.id == updated.id);
    if (index >= 0) {
      final newClips = List<TimelineClip>.from(project.clips);
      newClips[index] = updated;
      project = project.copyWith(
        clips: newClips,
        modifiedAt: DateTime.now(),
      );
      if (updated.isPrimary) {
        project = project.packPrimaryClips();
      }
      notifyListeners();
      autoSave();
    }
  }
}
