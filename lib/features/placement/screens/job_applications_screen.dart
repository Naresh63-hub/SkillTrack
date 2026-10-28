import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/job_application.dart';
import '../../../repositories/placement_repository.dart';
import 'add_edit_application_dialog.dart';

class JobApplicationsScreen extends StatefulWidget {
  const JobApplicationsScreen({super.key});

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  final PlacementRepository _repository = PlacementRepository();
  final TextEditingController _searchController = TextEditingController();

  List<JobApplication> _applications = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    final results = await _repository.getJobApplications(
      status: _selectedStatus,
      searchQuery: _searchController.text,
    );
    setState(() {
      _applications = results;
      _isLoading = false;
    });
  }

  Future<void> _addApplication() async {
    final newApp = await showDialog<JobApplication>(
      context: context,
      builder: (context) => const AddEditApplicationDialog(),
    );

    if (newApp != null) {
      await _repository.addJobApplication(newApp);
      _loadApplications();
    }
  }

  Future<void> _editApplication(JobApplication app) async {
    final updated = await showDialog<JobApplication>(
      context: context,
      builder: (context) => AddEditApplicationDialog(application: app),
    );

    if (updated != null) {
      await _repository.updateJobApplication(updated);
      _loadApplications();
    }
  }

  Future<void> _deleteApplication(JobApplication app) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Application',
      content:
          'Are you sure you want to delete application for "${app.companyName}"?',
    );

    if (confirmed) {
      await _repository.deleteJobApplication(app.id!);
      _loadApplications();
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brightAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Application'),
        onPressed: _addApplication,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchFilterBar(
              controller: _searchController,
              hintText: 'Search companies or roles...',
              onChanged: (_) => _loadApplications(),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildStatusChip('All'),
                ...AppStrings.applicationStatuses
                    .map((s) => _buildStatusChip(s)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.brightAccent))
                : _applications.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.work_outline,
                        title: _searchController.text.isNotEmpty ||
                                _selectedStatus != 'All'
                            ? 'No Matching Applications'
                            : 'No Job Applications Yet',
                        description: _searchController.text.isNotEmpty ||
                                _selectedStatus != 'All'
                            ? 'Try different search queries or pipeline status filters.'
                            : 'Track your campus placements, off-campus drives, online assessments, and interview rounds.',
                        actionLabel: 'Track Application',
                        onAction: _addApplication,
                      )
                    : RefreshIndicator(
                        color: AppColors.brightAccent,
                        backgroundColor: AppColors.cardBackground,
                        onRefresh: _loadApplications,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: _applications.length,
                          itemBuilder: (context, index) {
                            final app = _applications[index];
                            return _buildAppCard(app);
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
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.brightAccent : AppColors.border,
          width: isSelected ? 1.2 : 0.8,
        ),
        onSelected: (selected) {
          setState(() => _selectedStatus = status);
          _loadApplications();
        },
      ),
    );
  }

  Widget _buildAppCard(JobApplication app) {
    Color statusColor;
    switch (app.status) {
      case 'Selected':
        statusColor = AppColors.success;
        break;
      case 'Interview':
        statusColor = const Color(0xFFC084FC);
        break;
      case 'Assessment':
        statusColor = AppColors.brightAccent;
        break;
      case 'Applied':
        statusColor = AppColors.info;
        break;
      case 'Rejected':
      case 'Withdrawn':
        statusColor = AppColors.error;
        break;
      case 'Interested':
      case 'Preparing':
      default:
        statusColor = AppColors.warning;
        break;
    }

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  app.companyName,
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
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  app.status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
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
                    _editApplication(app);
                  } else if (action == 'delete') {
                    _deleteApplication(app);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit',
                        style: TextStyle(
                            color: AppColors.primaryText, fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            app.role,
            style: const TextStyle(
              color: AppColors.secondaryAccent,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Date & Deadlines
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Applied: ${DateFormatter.format(app.applicationDate)}',
                style:
                    const TextStyle(color: AppColors.mutedText, fontSize: 11.5),
              ),
              if (app.applicationDeadline != null &&
                  app.applicationDeadline!.isNotEmpty)
                Text(
                  'Deadline: ${DateFormatter.formatShort(app.applicationDeadline)}',
                  style: TextStyle(
                    color: app.isDeadlineApproaching
                        ? AppColors.error
                        : AppColors.secondaryText,
                    fontSize: 11.5,
                    fontWeight: app.isDeadlineApproaching
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
            ],
          ),

          // Interview Callout
          if (app.hasUpcomingInterview) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFC084FC).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFFC084FC).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, size: 15, color: Color(0xFFC084FC)),
                  const SizedBox(width: 6),
                  Text(
                    'Interview scheduled on: ${DateFormatter.format(app.interviewDate)}',
                    style: const TextStyle(
                        color: Color(0xFFC084FC),
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],

          if (app.requiredSkills != null && app.requiredSkills!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Required: ${app.requiredSkills!}',
              style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (app.jobDescriptionUrl != null &&
              app.jobDescriptionUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchUrl(app.jobDescriptionUrl!),
              child: const Row(
                children: [
                  Icon(Icons.link, size: 14, color: AppColors.secondaryAccent),
                  SizedBox(width: 4),
                  Text(
                    'View Job Description',
                    style: TextStyle(
                        color: AppColors.secondaryAccent,
                        fontSize: 11.5,
                        decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
