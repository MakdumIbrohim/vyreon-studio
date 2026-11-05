import '../../models/project.dart';
import '../../services/project_storage_service.dart';
import '../editor_controller_base.dart';

mixin EditorHistoryMixin on EditorControllerBase {
  final List<Project> undoStack = [];
  final List<Project> redoStack = [];
  static const int maxHistory = 30;

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  @override
  void pushUndo() {
    undoStack.add(project);
    if (undoStack.length > maxHistory) {
      undoStack.removeAt(0);
    }
    redoStack.clear();
  }

  void undo() {
    if (!canUndo) return;
    redoStack.add(project);
    project = undoStack.removeLast();
    clampPlayhead();
    notifyListeners();
    autoSave();
  }

  void redo() {
    if (!canRedo) return;
    undoStack.add(project);
    project = redoStack.removeLast();
    clampPlayhead();
    notifyListeners();
    autoSave();
  }

  void updateSettings(dynamic newSettings) {
    pushUndo();
    project = project.copyWith(
      settings: newSettings,
      modifiedAt: DateTime.now(),
    );
    notifyListeners();
    autoSave();
  }

  @override
  void autoSave() {
    ProjectStorageService.instance.saveProject(project);
  }
}
