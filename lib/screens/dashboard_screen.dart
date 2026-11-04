import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/project_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard/create_project_banner.dart';
import '../widgets/dashboard/project_card.dart';
import 'create_project_dialog.dart';
import 'editor_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final list = await ProjectStorageService.instance.loadProjects();
    setState(() {
      _projects = list;
      _isLoading = false;
    });
  }

  Future<void> _createNewProject() async {
    final newProject = await showDialog<Project>(
      context: context,
      builder: (_) => const CreateProjectDialog(),
    );

    if (newProject != null) {
      await ProjectStorageService.instance.saveProject(newProject);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditorScreen(project: newProject),
        ),
      );
      _loadProjects();
    }
  }

  Future<void> _openProject(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorScreen(project: project),
      ),
    );
    _loadProjects();
  }

  Future<void> _duplicateProject(Project project) async {
    await ProjectStorageService.instance.duplicateProject(project);
    _loadProjects();
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Project?'),
        content: Text('Are you sure you want to delete "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ProjectStorageService.instance.deleteProject(project.id);
      _loadProjects();
    }
  }

  Future<void> _renameProject(Project project) async {
    final controller = TextEditingController(text: project.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Rename Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'New Name',
            labelStyle: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Rename', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != project.name) {
      final updated = project.copyWith(
        name: newName,
        modifiedAt: DateTime.now(),
      );
      await ProjectStorageService.instance.saveProject(updated);
      _loadProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _projects.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.movie_creation,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VYREON STUDIO',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0)),
                Text('Professional Mobile Video Editor',
                    style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: _loadProjects,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadProjects,
              color: AppTheme.primary,
              child: CustomScrollView(
                slivers: [
                  // Hero "Create New Project" Banner
                  SliverToBoxAdapter(
                    child: CreateProjectBanner(onTap: _createNewProject),
                  ),

                  // Search bar & Project count header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          Text(
                            'MY PROJECTS (${filtered.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 180,
                            height: 34,
                            child: TextField(
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                hintStyle: const TextStyle(
                                    fontSize: 12, color: AppTheme.textMuted),
                                prefixIcon: const Icon(Icons.search,
                                    size: 16, color: AppTheme.textMuted),
                                filled: true,
                                fillColor: AppTheme.surfaceVariant,
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Projects Grid
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.video_library_outlined,
                                size: 48,
                                color:
                                    AppTheme.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 10),
                            const Text(
                              'No projects found',
                              style: TextStyle(
                                  fontSize: 14, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final project = filtered[index];
                            return ProjectCard(
                              project: project,
                              onOpen: () => _openProject(project),
                              onDuplicate: () => _duplicateProject(project),
                              onRename: () => _renameProject(project),
                              onDelete: () => _deleteProject(project),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
                  ),
                ],
              ),
            ),
    );
  }
}
