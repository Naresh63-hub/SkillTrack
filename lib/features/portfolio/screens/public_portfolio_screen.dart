import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/project.dart';
import '../../../models/certificate.dart';
import '../../../models/skill.dart';
import '../../certificates/screens/certificate_viewer_screen.dart';
import '../models/portfolio_data.dart';
import '../services/portfolio_repository.dart';
import '../widgets/student_card_share_sheet.dart';

class PublicPortfolioScreen extends StatefulWidget {
  final String? handle;
  final PortfolioData? initialData;

  const PublicPortfolioScreen({
    super.key,
    this.handle,
    this.initialData,
  });

  @override
  State<PublicPortfolioScreen> createState() => _PublicPortfolioScreenState();
}

class _PublicPortfolioScreenState extends State<PublicPortfolioScreen>
    with SingleTickerProviderStateMixin {
  final PortfolioRepository _repository = PortfolioRepository();
  PortfolioData? _data;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.initialData != null) {
      _data = widget.initialData;
      _isLoading = false;
    } else {
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _repository.loadPortfolio(handle: widget.handle);
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external link')),
        );
      }
    }
  }

  void _copyPortfolioUrl() {
    if (_data == null) return;
    final url = 'https://skill-track-ashy.vercel.app/#/p/${_data!.handle}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Expanded(child: Text('Portfolio URL copied: $url')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Portfolio')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.brightAccent),
        ),
      );
    }

    final data = _data!;
    final profile = data.profile;
    final name = profile.name.isNotEmpty ? profile.name : 'Student Name';
    final role = profile.targetJobRole.isNotEmpty
        ? profile.targetJobRole
        : 'Aspiring Software Engineer';

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primaryPurple.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded,
                      color: AppColors.brightAccent, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'VERIFIED STUDENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brightAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Copy Public URL',
            onPressed: _copyPortfolioUrl,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            tooltip: 'Share Student Card',
            onPressed: () => StudentCardShareSheet.show(context, data),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Student Card
                        _buildHeroHeader(name, role, data),
                        const SizedBox(height: 14),

                        // Stats Highlights Row
                        _buildStatsRow(data),
                        const SizedBox(height: 14),

                        // Tab Bar
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: AppColors.brightAccent,
                            unselectedLabelColor: AppColors.secondaryText,
                            indicatorColor: AppColors.brightAccent,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                            tabs: [
                              Tab(
                                icon: const Icon(Icons.rocket_launch_rounded,
                                    size: 18),
                                text: 'Projects (${data.projects.length})',
                              ),
                              Tab(
                                icon: const Icon(Icons.verified_rounded,
                                    size: 18),
                                text: 'Certs (${data.certificates.length})',
                              ),
                              Tab(
                                icon: const Icon(Icons.bolt_rounded, size: 18),
                                text: 'Skills (${data.skills.length})',
                              ),
                              const Tab(
                                icon: Icon(Icons.school_rounded, size: 18),
                                text: 'Bio & Academics',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildProjectsTab(data.projects),
                _buildCertificatesTab(data.certificates),
                _buildSkillsTab(data.skills),
                _buildBioAndEducationTab(data),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyPortfolioUrl,
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Copy Profile Link'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => StudentCardShareSheet.show(context, data),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share Student Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(String name, String role, PortfolioData data) {
    final profile = data.profile;
    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryPurple, AppColors.brightAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brightAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brightAccent,
                        ),
                      ),
                    ),
                    if (profile.college.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${profile.degree.isNotEmpty ? "${profile.degree} • " : ""}${profile.college}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Text(
                profile.bio,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.primaryText,
                  height: 1.4,
                ),
              ),
            ),
          ],

          // Professional & social links row
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (profile.githubUrl.isNotEmpty)
                _buildSocialPill(
                  icon: Icons.code_rounded,
                  label: 'GitHub',
                  url: profile.githubUrl,
                  color: AppColors.primaryPurple,
                ),
              if (profile.linkedinUrl.isNotEmpty)
                _buildSocialPill(
                  icon: Icons.business_center_rounded,
                  label: 'LinkedIn',
                  url: profile.linkedinUrl,
                  color: const Color(0xFF0A66C2),
                ),
              if (profile.portfolioUrl.isNotEmpty &&
                  !profile.portfolioUrl.contains('/#/p/'))
                _buildSocialPill(
                  icon: Icons.language_rounded,
                  label: 'Website',
                  url: profile.portfolioUrl,
                  color: Colors.tealAccent,
                ),
              if (profile.email.isNotEmpty)
                _buildSocialPill(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  url: 'mailto:${profile.email}',
                  color: Colors.amberAccent,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialPill({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_outward_rounded, size: 10, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(PortfolioData data) {
    return Row(
      children: [
        _buildStatCard(
          title: 'Live Projects',
          value: '${data.projects.length}',
          icon: Icons.rocket_launch_rounded,
          color: AppColors.brightAccent,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          title: 'Verified Certs',
          value: '${data.certificates.length}',
          icon: Icons.verified_rounded,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          title: 'Core Skills',
          value: '${data.skills.length}',
          icon: Icons.bolt_rounded,
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: CustomCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Projects Tab
  Widget _buildProjectsTab(List<Project> projects) {
    if (projects.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.folder_open_rounded,
        title: 'No projects showcase yet',
        description: 'Student projects with GitHub repos and live demos appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(Project project) {
    final links = project.deploymentLinks;
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      project.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.lightPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: project.isCompleted
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : AppColors.primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  project.status,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: project.isCompleted
                        ? const Color(0xFF10B981)
                        : AppColors.brightAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project.shortDescription,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.secondaryText,
              height: 1.35,
            ),
          ),
          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: project.technologies.map((tech) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Text(
                    tech,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (links.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: links.map((link) {
                return _buildDeployLinkButton(link);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeployLinkButton(ProjectDeploymentLink link) {
    Color btnColor;
    IconData icon;
    if (link.type == 'github') {
      btnColor = AppColors.primaryPurple;
      icon = Icons.code_rounded;
    } else if (link.type == 'vercel') {
      btnColor = Colors.lightBlueAccent;
      icon = Icons.cloud_done_rounded;
    } else if (link.type == 'render') {
      btnColor = Colors.tealAccent;
      icon = Icons.storage_rounded;
    } else {
      btnColor = AppColors.brightAccent;
      icon = Icons.open_in_browser_rounded;
    }

    return OutlinedButton.icon(
      onPressed: () => _launchUrl(link.url),
      icon: Icon(icon, size: 14, color: btnColor),
      label: Text(
        link.label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: btnColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: BorderSide(color: btnColor.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // 2. Certificates Tab
  Widget _buildCertificatesTab(List<Certificate> certs) {
    if (certs.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.verified_outlined,
        title: 'No certificates added yet',
        description: 'Verified credentials and certificates will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: certs.length,
      itemBuilder: (context, index) {
        final cert = certs[index];
        return _buildCertificateCard(cert);
      },
    );
  }

  Widget _buildCertificateCard(Certificate cert) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cert.name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cert.issuingOrganization} • ${cert.category}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    if (cert.credentialId != null &&
                        cert.credentialId!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'ID: ${cert.credentialId}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.brightAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (cert.description != null && cert.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              cert.description!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Issued: ${cert.completionDate}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondaryText,
                ),
              ),
              const Spacer(),
              if (cert.hasVerificationUrl)
                TextButton.icon(
                  onPressed: () => _launchUrl(cert.verificationUrl!),
                  icon: const Icon(Icons.verified_user_outlined, size: 14),
                  label: const Text('Verify Online',
                      style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              if (cert.hasFile)
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) =>
                            CertificateViewerScreen(certificate: cert),
                      ),
                    );
                  },
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                  label: const Text('View Document',
                      style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brightAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Skills Tab
  Widget _buildSkillsTab(List<Skill> skills) {
    if (skills.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.bolt_outlined,
        title: 'No skills tracked yet',
        description: 'Student technical skills and proficiency levels appear here.',
      );
    }

    // Group skills by category
    final grouped = <String, List<Skill>>{};
    for (final s in skills) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brightAccent,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((skill) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          skill.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getProficiencyColor(skill.proficiencyLevel)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            skill.proficiencyLevel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color:
                                  _getProficiencyColor(skill.proficiencyLevel),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getProficiencyColor(String level) {
    switch (level.toLowerCase()) {
      case 'expert':
        return const Color(0xFF10B981);
      case 'advanced':
        return AppColors.brightAccent;
      case 'intermediate':
        return const Color(0xFFF59E0B);
      case 'beginner':
      default:
        return AppColors.lightPurple;
    }
  }

  // 4. Bio & Academics Tab
  Widget _buildBioAndEducationTab(PortfolioData data) {
    final profile = data.profile;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Academic Details Card
        CustomCard(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.school_rounded,
                      color: AppColors.brightAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Academic Information',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAcademicRow('College / University', profile.college),
              _buildAcademicRow('Degree & Branch',
                  '${profile.degree} ${profile.branch.isNotEmpty ? "(${profile.branch})" : ""}'),
              _buildAcademicRow('Current Semester', profile.currentSemester),
              _buildAcademicRow('Graduation Year', profile.graduationYear),
              if (profile.city.isNotEmpty)
                _buildAcademicRow('Location', profile.city),
            ],
          ),
        ),

        // Achievements Section
        if (data.achievements.isNotEmpty)
          CustomCard(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: Color(0xFFF59E0B), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Honors & Hackathon Achievements',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...data.achievements.map((ach) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.stars_rounded,
                            size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ach.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              if (ach.description != null &&
                                  ach.description!.isNotEmpty)
                                Text(
                                  ach.description!,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

        // GitHub Repositories (if connected / imported)
        if (data.githubRepos.isNotEmpty)
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.code_rounded,
                        color: AppColors.primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'GitHub Repositories',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...data.githubRepos.take(5).map((repo) {
                  return InkWell(
                    onTap: () => _launchUrl(repo.htmlUrl),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.bookmark_border_rounded,
                              size: 16, color: AppColors.brightAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  repo.name,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                if (repo.description != null &&
                                    repo.description!.isNotEmpty)
                                  Text(
                                    repo.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 2),
                              Text('${repo.stargazersCount}',
                                  style: const TextStyle(fontSize: 11)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_outward_rounded,
                                  size: 14, color: AppColors.secondaryText),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAcademicRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
