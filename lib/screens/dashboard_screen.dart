import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/project_storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/dashboard/create_project_banner.dart';
import '../widgets/dashboard/dashboard_search_bar.dart';
import '../widgets/dashboard/project_action_dialogs.dart';
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
    final confirmed = await ProjectActionDialogs.showDeleteConfirmation(
      context,
      project,
    );
    if (confirmed == true) {
      await ProjectStorageService.instance.deleteProject(project.id);
      _loadProjects();
    }
  }

  Future<void> _renameProject(Project project) async {
    final newName = await ProjectActionDialogs.showRename(
      context,
      project,
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VYREON STUDIO',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Professional Mobile Video Editor',
                    style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
                    child: DashboardSearchBar(
                      projectCount: filtered.length,
                      onSearchChanged: (val) =>
                          setState(() => _searchQuery = val),
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
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              ResponsiveLayout.getDashboardColumns(context),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: ResponsiveLayout.isPortrait(context)
                              ? 1.2
                              : 1.1,
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
