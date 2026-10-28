import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/project.dart';
import '../../../repositories/projects_repository.dart';
import 'add_edit_project_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project initialProject;

  const ProjectDetailScreen({super.key, required this.initialProject});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project;
  final ProjectsRepository _repository = ProjectsRepository();

  @override
  void initState() {
    super.initState();
    _project = widget.initialProject;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open external link')),
      );
    }
  }

  Future<void> _editProject() async {
    final updated = await Navigator.of(context).push<Project>(
      MaterialPageRoute(
        builder: (context) => AddEditProjectScreen(project: _project),
      ),
    );

    if (updated != null) {
      await _repository.updateProject(updated);
      setState(() => _project = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated successfully')),
        );
      }
    }
  }

  Future<void> _deleteProject() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Project',
      content:
          'Are you sure you want to delete "${_project.name}" from your portfolio?',
    );

    if (confirmed && mounted) {
      await _repository.deleteProject(_project.id!);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (_project.status) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Edit Project',
            onPressed: _editProject,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 20),
            tooltip: 'Delete Project',
            onPressed: _deleteProject,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _project.category,
                          style: const TextStyle(
                              color: AppColors.secondaryText, fontSize: 12),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _project.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _project.name,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _project.shortDescription,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Technologies
                  if (_project.technologies.isNotEmpty) ...[
                    const Text(
                      'Tech Stack',
                      style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _project.technologies.map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.elevatedSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.primaryAccent
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              color: AppColors.brightAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Links (GitHub / Demo)
            Row(
              children: [
                if (_project.githubUrl != null &&
                    _project.githubUrl!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.code, size: 18),
                      label: const Text('GitHub Repo'),
                      onPressed: () => _launchUrl(_project.githubUrl!),
                    ),
                  ),
                if (_project.githubUrl != null &&
                    _project.githubUrl!.isNotEmpty &&
                    _project.liveDemoUrl != null &&
                    _project.liveDemoUrl!.isNotEmpty)
                  const SizedBox(width: 10),
                if (_project.liveDemoUrl != null &&
                    _project.liveDemoUrl!.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.launch, size: 18),
                      label: const Text('Live Demo'),
                      onPressed: () => _launchUrl(_project.liveDemoUrl!),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Key Features
            if (_project.keyFeatures != null &&
                _project.keyFeatures!.isNotEmpty) ...[
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Key Features',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._project.keyFeatures!
                        .split('\n')
                        .where((l) => l.trim().isNotEmpty)
                        .map((feat) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color: AppColors.brightAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                feat,
                                style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 13,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Problems Solved
            if (_project.problemsSolved != null &&
                _project.problemsSolved!.isNotEmpty) ...[
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Problems Solved',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _project.problemsSolved!,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // What Learned
            if (_project.whatLearned != null &&
                _project.whatLearned!.isNotEmpty) ...[
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What I Learned',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _project.whatLearned!,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Timeline Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Project Timeline',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Started:',
                          style: TextStyle(
                              color: AppColors.mutedText, fontSize: 13)),
                      Text(
                        DateFormatter.format(_project.startDate),
                        style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Completed:',
                          style: TextStyle(
                              color: AppColors.mutedText, fontSize: 13)),
                      Text(
                        DateFormatter.format(_project.completionDate),
                        style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
