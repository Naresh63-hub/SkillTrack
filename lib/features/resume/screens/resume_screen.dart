import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../models/student_profile.dart';
import '../../../models/education.dart';
import '../../../models/skill.dart';
import '../../../models/project.dart';
import '../../../models/certificate.dart';
import '../../../models/achievement.dart';
import '../../../repositories/profile_repository.dart';
import '../../../repositories/skills_repository.dart';
import '../../../repositories/projects_repository.dart';
import '../../../repositories/certificates_repository.dart';
import '../../../services/resume_service.dart';
import 'resume_preview_screen.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final ProfileRepository _profileRepo = ProfileRepository();
  final SkillsRepository _skillsRepo = SkillsRepository();
  final ProjectsRepository _projectsRepo = ProjectsRepository();
  final CertificatesRepository _certsRepo = CertificatesRepository();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _roleController;
  late TextEditingController _githubController;
  late TextEditingController _linkedinController;
  late TextEditingController _bioController;

  StudentProfile? _profile;
  List<Education> _education = [];
  List<Skill> _allSkills = [];
  List<Project> _allProjects = [];
  List<Certificate> _allCerts = [];
  List<Achievement> _achievements = [];

  final Set<int> _selectedSkillIds = {};
  final Set<int> _selectedProjectIds = {};
  final Set<int> _selectedCertIds = {};

  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    _roleController = TextEditingController();
    _githubController = TextEditingController();
    _linkedinController = TextEditingController();
    _bioController = TextEditingController();
    _loadResumeData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _roleController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadResumeData() async {
    setState(() => _isLoading = true);
    final profile = await _profileRepo.getProfile();
    final education = await _profileRepo.getEducationList();
    final achievements = await _profileRepo.getAchievements();
    final skills = await _skillsRepo.getAllSkills();
    final projects = await _projectsRepo.getAllProjects();
    final certs = await _certsRepo.getAllCertificates();

    _profile = profile;
    _education = education;
    _achievements = achievements;
    _allSkills = skills;
    _allProjects = projects;
    _allCerts = certs;

    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _cityController.text = profile.city;
    _roleController.text = profile.targetJobRole;
    _githubController.text = profile.githubUrl;
    _linkedinController.text = profile.linkedinUrl;
    _bioController.text = profile.bio;

    // Default select all
    for (final s in skills) {
      if (s.id != null) _selectedSkillIds.add(s.id!);
    }
    for (final p in projects) {
      if (p.id != null) _selectedProjectIds.add(p.id!);
    }
    for (final c in certs) {
      if (c.id != null) _selectedCertIds.add(c.id!);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _generatePdf() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your name for the resume.')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final updatedProfile = (_profile ?? StudentProfile(name: _nameController.text)).copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        targetJobRole: _roleController.text.trim(),
        githubUrl: _githubController.text.trim(),
        linkedinUrl: _linkedinController.text.trim(),
        bio: _bioController.text.trim(),
      );

      // Save changes back to profile
      await _profileRepo.saveProfile(updatedProfile);

      final selectedSkills = _allSkills.where((s) => _selectedSkillIds.contains(s.id)).toList();
      final selectedProjects = _allProjects.where((p) => _selectedProjectIds.contains(p.id)).toList();
      final selectedCerts = _allCerts.where((c) => _selectedCertIds.contains(c.id)).toList();

      final resumeData = ResumeData(
        profile: updatedProfile,
        education: _education,
        skills: selectedSkills,
        projects: selectedProjects,
        certificates: selectedCerts,
        achievements: _achievements,
      );

      final pdfBytes = await ResumeService.generateResumePdf(resumeData);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResumePreviewScreen(pdfBytes: pdfBytes),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate resume: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _addEducationDialog() async {
    final instCtrl = TextEditingController();
    final degCtrl = TextEditingController(text: 'B.Tech');
    final fieldCtrl = TextEditingController(text: 'Computer Science & Engineering');
    final startCtrl = TextEditingController(text: '2022');
    final endCtrl = TextEditingController(text: '2026');
    final gradeCtrl = TextEditingController(text: '8.5 CGPA');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Education Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: instCtrl, decoration: const InputDecoration(labelText: 'College / School *')),
              const SizedBox(height: 8),
              TextField(controller: degCtrl, decoration: const InputDecoration(labelText: 'Degree (e.g. B.Tech) *')),
              const SizedBox(height: 8),
              TextField(controller: fieldCtrl, decoration: const InputDecoration(labelText: 'Major / Field of Study *')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Year'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Year'))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: 'CGPA / Percentage')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (instCtrl.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final edu = Education(
        institution: instCtrl.text.trim(),
        degree: degCtrl.text.trim(),
        fieldOfStudy: fieldCtrl.text.trim(),
        startYear: startCtrl.text.trim(),
        endYear: endCtrl.text.trim(),
        gradeOrCgpa: gradeCtrl.text.trim().isEmpty ? null : gradeCtrl.text.trim(),
      );
      await _profileRepo.addEducation(edu);
      _loadResumeData();
    }
  }

  Future<void> _addAchievementDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Honor / Achievement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title / Award *')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) Navigator.of(ctx).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final ach = Achievement(
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      );
      await _profileRepo.addAchievement(ach);
      _loadResumeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ATS Resume Builder')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.brightAccent)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ATS Resume Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.brightAccent),
            tooltip: 'Generate PDF',
            onPressed: _isGenerating ? null : _generatePdf,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.secondaryBackground,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          icon: _isGenerating
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.picture_as_pdf),
          label: Text(_isGenerating ? 'Compiling PDF...' : 'Generate & Export ATS Resume'),
          onPressed: _isGenerating ? null : _generatePdf,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner: Generate Your Resume (Screen 12 in design mockup)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondaryBackground, AppColors.cardBackground],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description,
                            color: AppColors.brightAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Generate Your Resume',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Use your saved information to create a professional ATS-friendly resume',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChecklistChip('Personal Info',
                          _nameController.text.trim().isNotEmpty),
                      _buildChecklistChip('Education', _education.isNotEmpty),
                      _buildChecklistChip(
                          'Skills', _selectedSkillIds.isNotEmpty),
                      _buildChecklistChip(
                          'Projects', _selectedProjectIds.isNotEmpty),
                      _buildChecklistChip(
                          'Certifications', _selectedCertIds.isNotEmpty),
                      _buildChecklistChip(
                          'Achievements', _achievements.isNotEmpty),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isGenerating ? null : _generatePdf,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.picture_as_pdf, size: 18),
                      label: Text(
                        _isGenerating
                            ? 'Compiling PDF...'
                            : 'Generate ATS Resume',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact Info Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Header & Contact Information',
                    style: TextStyle(color: AppColors.primaryText, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name *')),
                  const SizedBox(height: 10),
                  TextFormField(controller: _roleController, decoration: const InputDecoration(labelText: 'Target Job Title')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'City / Location'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: _githubController, decoration: const InputDecoration(labelText: 'GitHub URL'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: _linkedinController, decoration: const InputDecoration(labelText: 'LinkedIn URL')),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Professional Summary',
                      hintText: 'Passionate computer science student specializing in...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Education Section
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Education History',
                        style: TextStyle(color: AppColors.primaryText, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Degree', style: TextStyle(fontSize: 12)),
                        onPressed: _addEducationDialog,
                      ),
                    ],
                  ),
                  if (_education.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No education entries added.', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
                    )
                  else
                    ..._education.map((e) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.institution, style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('${e.degree} in ${e.fieldOfStudy} (${e.startYear}-${e.endYear})', style: const TextStyle(color: AppColors.mutedText, fontSize: 11.5)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          onPressed: () async {
                            await _profileRepo.deleteEducation(e.id!);
                            _loadResumeData();
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Select Skills to Include
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Technical Skills to Include',
                        style: TextStyle(color: AppColors.primaryText, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_selectedSkillIds.length} / ${_allSkills.length}',
                        style: const TextStyle(color: AppColors.brightAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _allSkills.map((s) {
                      final isSelected = _selectedSkillIds.contains(s.id);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(s.name),
                        selectedColor: AppColors.elevatedSurface,
                        backgroundColor: AppColors.surfaceVariant,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.brightAccent : AppColors.secondaryText,
                          fontSize: 11.5,
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedSkillIds.add(s.id!);
                            } else {
                              _selectedSkillIds.remove(s.id!);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Select Projects to Include
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Projects to Include',
                        style: TextStyle(color: AppColors.primaryText, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_selectedProjectIds.length} / ${_allProjects.length}',
                        style: const TextStyle(color: AppColors.brightAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._allProjects.map((p) {
                    final isSelected = _selectedProjectIds.contains(p.id);
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isSelected,
                      title: Text(p.name, style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(p.shortDescription, style: const TextStyle(color: AppColors.mutedText, fontSize: 11), maxLines: 1),
                      activeColor: AppColors.brightAccent,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedProjectIds.add(p.id!);
                          } else {
                            _selectedProjectIds.remove(p.id!);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Select Certifications
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Certifications to Include',
                        style: TextStyle(color: AppColors.primaryText, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_selectedCertIds.length} / ${_allCerts.length}',
                        style: const TextStyle(color: AppColors.brightAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._allCerts.map((c) {
                    final isSelected = _selectedCertIds.contains(c.id);
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isSelected,
                      title: Text(c.name, style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(c.issuingOrganization, style: const TextStyle(color: AppColors.mutedText, fontSize: 11)),
                      activeColor: AppColors.brightAccent,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedCertIds.add(c.id!);
                          } else {
                            _selectedCertIds.remove(c.id!);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Honors & Achievements
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Honors & Achievements',
                        style: TextStyle(color: AppColors.primaryText, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Award', style: TextStyle(fontSize: 12)),
                        onPressed: _addAchievementDialog,
                      ),
                    ],
                  ),
                  if (_achievements.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No awards or achievements listed.', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
                    )
                  else
                    ..._achievements.map((a) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(a.title, style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: a.description != null ? Text(a.description!, style: const TextStyle(color: AppColors.mutedText, fontSize: 11.5)) : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          onPressed: () async {
                            await _profileRepo.deleteAchievement(a.id!);
                            _loadResumeData();
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistChip(String label, bool isComplete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isComplete
            ? const Color(0xFF10B981).withValues(alpha: 0.16)
            : AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete
              ? const Color(0xFF10B981).withValues(alpha: 0.45)
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isComplete ? const Color(0xFF10B981) : AppColors.mutedText,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isComplete ? AppColors.primaryText : AppColors.mutedText,
              fontSize: 11,
              fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
