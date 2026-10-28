import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../models/project.dart';
import '../../../repositories/projects_repository.dart';
import 'add_edit_project_screen.dart';
import 'project_detail_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ProjectsRepository _repository = ProjectsRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Project> _projects = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';

  final List<String> _statusFilters = [
    'All',
    'In Progress',
    'Completed',
    'Planned',
    'On Hold'
  ];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final results = await _repository.getAllProjects(
      status: _selectedStatus,
      searchQuery: _searchController.text,
    );
    setState(() {
      _projects = results;
      _isLoading = false;
    });
  }

  Future<void> _addProject() async {
    final newProject = await Navigator.of(context).push<Project>(
      MaterialPageRoute(
        builder: (context) => const AddEditProjectScreen(),
      ),
    );

    if (newProject != null) {
      await _repository.addProject(newProject);
      _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully')),
        );
      }
    }
  }

  Future<void> _editProject(Project project) async {
    final updated = await Navigator.of(context).push<Project>(
      MaterialPageRoute(
        builder: (context) => AddEditProjectScreen(project: project),
      ),
    );

    if (updated != null) {
      await _repository.updateProject(updated);
      _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated successfully')),
        );
      }
    }
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Project',
      content: 'Are you sure you want to delete "${project.name}"?',
    );

    if (confirmed) {
      await _repository.deleteProject(project.id!);
      _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project deleted')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Portfolio'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brightAccent,
        foregroundColor: Colors.white,
        onPressed: _addProject,
        tooltip: 'New Project',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchFilterBar(
              controller: _searchController,
              hintText: 'Search projects or tech stack...',
              onChanged: (_) => _loadProjects(),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _statusFilters.map((s) => _buildStatusChip(s)).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.brightAccent))
                : _projects.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.developer_mode,
                        title: _searchController.text.isNotEmpty ||
                                _selectedStatus != 'All'
                            ? 'No Matching Projects'
                            : 'No Projects Added Yet',
                        description: _searchController.text.isNotEmpty ||
                                _selectedStatus != 'All'
                            ? 'Try different keywords or switch status filters.'
                            : 'Showcase your engineering capabilities, hackathons, and B.Tech projects with GitHub links and tech stacks.',
                        actionLabel: 'Create Project',
                        onAction: _addProject,
                      )
                    : RefreshIndicator(
                        color: AppColors.brightAccent,
                        backgroundColor: AppColors.cardBackground,
                        onRefresh: _loadProjects,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: _projects.length,
                          itemBuilder: (context, index) {
                            final project = _projects[index];
                            return _buildProjectCard(project);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(status),
        selectedColor: AppColors.elevatedSurface,
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.brightAccent : AppColors.secondaryText,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.brightAccent : AppColors.border,
          width: isSelected ? 1.2 : 0.8,
        ),
        onSelected: (selected) {
          setState(() => _selectedStatus = status);
          _loadProjects();
        },
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    Color statusColor;
    switch (project.status) {
      case 'Completed':
        statusColor = AppColors.success;
        break;
      case 'In Progress':
        statusColor = AppColors.brightAccent;
        break;
      case 'On Hold':
        statusColor = AppColors.warning;
        break;
      case 'Planned':
      default:
        statusColor = AppColors.info;
        break;
    }

    return CustomCard(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(initialProject: project),
          ),
        );
        if (result == true || result != null) {
          _loadProjects();
        }
      },
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.5), width: 0.8),
                ),
                child: Text(
                  project.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    size: 18, color: AppColors.mutedText),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppColors.secondaryBackground,
                onSelected: (action) {
                  if (action == 'edit') {
                    _editProject(project);
                  } else if (action == 'delete') {
                    _deleteProject(project);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit,
                            size: 16, color: AppColors.secondaryText),
                        SizedBox(width: 8),
                        Text('Edit',
                            style: TextStyle(
                                color: AppColors.primaryText, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(
                                color: AppColors.error, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            project.shortDescription,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12.5,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: project.technologies.take(4).map((tech) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Text(
                    tech,
                    style: const TextStyle(
                      color: AppColors.secondaryAccent,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                project.category,
                style:
                    const TextStyle(color: AppColors.mutedText, fontSize: 11),
              ),
              Row(
                children: [
                  if (project.githubUrl != null &&
                      project.githubUrl!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.code,
                          size: 18, color: AppColors.secondaryText),
                      tooltip: 'Open GitHub',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _launchUrl(project.githubUrl!),
                    ),
                  if (project.liveDemoUrl != null &&
                      project.liveDemoUrl!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.launch,
                          size: 18, color: AppColors.brightAccent),
                      tooltip: 'Open Live Demo',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _launchUrl(project.liveDemoUrl!),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
