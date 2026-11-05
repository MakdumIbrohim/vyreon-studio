import 'dart:convert';
import 'dart:io';
import '../models/project.dart';

class ProjectStorageService {
  static final ProjectStorageService instance = ProjectStorageService._();
  ProjectStorageService._();

  List<Project>? _cachedProjects;

  File _getStorageFile() {
    try {
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null && home.isNotEmpty) {
        final dir = Directory('$home/.vyreon_studio');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        return File('${dir.path}/projects.json');
      }
    } catch (_) {
      // Fallback
    }
    return File('.vyreon_projects.json');
  }

  Future<List<Project>> loadProjects() async {
    if (_cachedProjects != null) return _cachedProjects!;

    final file = _getStorageFile();
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final List<dynamic> list = jsonDecode(content);
        _cachedProjects = list
            .map((item) => Project.fromJson(item as Map<String, dynamic>))
            .toList();
        return _cachedProjects!;
      } catch (e) {
        // Fallback on corrupt file
      }
    }

    _cachedProjects = [];
    return _cachedProjects!;
  }

  Future<void> saveProjects(List<Project> projects) async {
    _cachedProjects = projects;
    try {
      final file = _getStorageFile();
      final jsonStr = jsonEncode(projects.map((p) => p.toJson()).toList());
      await file.writeAsString(jsonStr, flush: true);
    } catch (_) {
      // Ignore write errors on constrained environments
    }
  }

  Future<void> saveProject(Project project) async {
    final list = await loadProjects();
    final index = list.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      list[index] = project.copyWith(modifiedAt: DateTime.now());
    } else {
      list.insert(0, project);
    }
    await saveProjects(list);
  }

  Future<void> deleteProject(String id) async {
    final list = await loadProjects();
    list.removeWhere((p) => p.id == id);
    await saveProjects(list);
  }

  Future<Project> duplicateProject(Project source) async {
    final now = DateTime.now();
    final copy = source.copyWith(
      id: 'proj_${now.millisecondsSinceEpoch}',
      name: '${source.name} (Copy)',
      createdAt: now,
      modifiedAt: now,
    );
    await saveProject(copy);
    return copy;
  }
}
