import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import '../models/project.dart';
import '../models/timeline_clip.dart';
import 'project_storage_service.dart';

class ProjectPackageResult {
  final bool success;
  final String? filePath;
  final Project? project;
  final String? error;

  const ProjectPackageResult({
    required this.success,
    this.filePath,
    this.project,
    this.error,
  });
}

class ProjectPackageService {
  static final ProjectPackageService instance = ProjectPackageService._();
  ProjectPackageService._();

  Directory _getExportDirectory() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    final dir = Directory('$home/.vyreon_studio/packages');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Directory _getProjectExtractDirectory(String projectId) {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    final dir = Directory('$home/.vyreon_studio/projects/$projectId/assets');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Exports a project and all its referenced media assets into a single `.vyreon` bundle file.
  Future<ProjectPackageResult> exportBundle(
    Project project, {
    String? targetDirectoryPath,
  }) async {
    try {
      final archive = Archive();
      final packagedClips = <TimelineClip>[];
      int assetCounter = 0;

      for (final clip in project.clips) {
        if (clip.assetPath != null && clip.assetPath!.isNotEmpty) {
          final sourceFile = File(clip.assetPath!);
          if (await sourceFile.exists()) {
            final filename = sourceFile.uri.pathSegments.last;
            final archivePath = 'assets/${clip.id}_$filename';

            final bytes = await sourceFile.readAsBytes();
            archive.addFile(ArchiveFile.bytes(archivePath, bytes));
            assetCounter++;

            packagedClips.add(clip.copyWith(assetPath: archivePath));
            continue;
          }
        }
        packagedClips.add(clip);
      }

      final packagedProject = project.copyWith(clips: packagedClips);
      final projectJsonStr = jsonEncode(packagedProject.toJson());
      archive.addFile(ArchiveFile.string('project.json', projectJsonStr));

      final manifest = {
        'format': 'vyreon_project_bundle',
        'formatVersion': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'projectId': project.id,
        'projectName': project.name,
        'assetCount': assetCounter,
      };
      archive.addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest)));

      final zipData = ZipEncoder().encode(archive);
      final exportDir = targetDirectoryPath != null
          ? Directory(targetDirectoryPath)
          : _getExportDirectory();

      final safeName = project.name
          .replaceAll(RegExp(r'[^\w\s\.-]'), '_')
          .replaceAll(' ', '_');
      final outputFile = File('${exportDir.path}/$safeName.vyreon');
      await outputFile.writeAsBytes(zipData, flush: true);

      return ProjectPackageResult(
        success: true,
        filePath: outputFile.path,
        project: project,
      );
    } catch (e) {
      return ProjectPackageResult(
        success: false,
        error: 'Export failed: $e',
      );
    }
  }

  /// Imports a `.vyreon` project bundle, extracts assets, and registers it with ProjectStorageService.
  Future<ProjectPackageResult> importBundle(String bundleFilePath) async {
    try {
      final bundleFile = File(bundleFilePath);
      if (!await bundleFile.exists()) {
        return const ProjectPackageResult(
          success: false,
          error: 'Bundle file not found.',
        );
      }

      final bytes = await bundleFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? projectFile;
      for (final f in archive.files) {
        if (f.name == 'project.json') {
          projectFile = f;
          break;
        }
      }

      if (projectFile == null) {
        return const ProjectPackageResult(
          success: false,
          error: 'Invalid bundle: project.json missing.',
        );
      }

      final projectJsonContent = utf8.decode(projectFile.content as List<int>);
      final rawProject = Project.fromJson(jsonDecode(projectJsonContent));

      final newProjectId = 'proj_pkg_${DateTime.now().millisecondsSinceEpoch}';
      final extractDir = _getProjectExtractDirectory(newProjectId);

      final restoredClips = <TimelineClip>[];
      for (final clip in rawProject.clips) {
        if (clip.assetPath != null && clip.assetPath!.startsWith('assets/')) {
          final internalName = clip.assetPath!;
          ArchiveFile? mediaFile;
          for (final f in archive.files) {
            if (f.name == internalName) {
              mediaFile = f;
              break;
            }
          }

          if (mediaFile != null) {
            final localFileName = internalName.split('/').last;
            final targetLocalFile = File('${extractDir.path}/$localFileName');
            await targetLocalFile.writeAsBytes(
              mediaFile.content as List<int>,
              flush: true,
            );
            restoredClips.add(clip.copyWith(assetPath: targetLocalFile.path));
            continue;
          }
        }
        restoredClips.add(clip);
      }

      final restoredProject = rawProject.copyWith(
        id: newProjectId,
        name: '${rawProject.name} (Imported)',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        clips: restoredClips,
      );

      await ProjectStorageService.instance.saveProject(restoredProject);

      return ProjectPackageResult(
        success: true,
        filePath: bundleFilePath,
        project: restoredProject,
      );
    } catch (e) {
      return ProjectPackageResult(
        success: false,
        error: 'Import failed: $e',
      );
    }
  }
}
