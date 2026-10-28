import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/utils/validators.dart';
import '../../../models/student_profile.dart';
import '../../../repositories/profile_repository.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _repository = ProfileRepository();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _collegeController;
  late TextEditingController _degreeController;
  late TextEditingController _branchController;
  late TextEditingController _semesterController;
  late TextEditingController _gradYearController;
  late TextEditingController _targetRoleController;
  late TextEditingController _githubController;
  late TextEditingController _linkedinController;
  late TextEditingController _bioController;

  StudentProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    _collegeController = TextEditingController();
    _degreeController = TextEditingController();
    _branchController = TextEditingController();
    _semesterController = TextEditingController();
    _gradYearController = TextEditingController();
    _targetRoleController = TextEditingController();
    _githubController = TextEditingController();
    _linkedinController = TextEditingController();
    _bioController = TextEditingController();

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _collegeController.dispose();
    _degreeController.dispose();
    _branchController.dispose();
    _semesterController.dispose();
    _gradYearController.dispose();
    _targetRoleController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final p = await _repository.getProfile();
    _profile = p;
    _nameController.text = p.name;
    _emailController.text = p.email;
    _phoneController.text = p.phone;
    _cityController.text = p.city;
    _collegeController.text = p.college;
    _degreeController.text = p.degree;
    _branchController.text = p.branch;
    _semesterController.text = p.currentSemester;
    _gradYearController.text = p.graduationYear;
    _targetRoleController.text = p.targetJobRole;
    _githubController.text = p.githubUrl;
    _linkedinController.text = p.linkedinUrl;
    _bioController.text = p.bio;

    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final updated =
        (_profile ?? StudentProfile(name: _nameController.text)).copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      college: _collegeController.text.trim(),
      degree: _degreeController.text.trim(),
      branch: _branchController.text.trim(),
      currentSemester: _semesterController.text.trim(),
      graduationYear: _gradYearController.text.trim(),
      targetJobRole: _targetRoleController.text.trim(),
      githubUrl: _githubController.text.trim(),
      linkedinUrl: _linkedinController.text.trim(),
      bio: _bioController.text.trim(),
    );

    await _repository.saveProfile(updated);
    setState(() {
      _profile = updated;
      _isEditing = false;
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Profile')),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.brightAccent)),
      );
    }

    final p = _profile!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel : Icons.edit, size: 20),
            tooltip: _isEditing ? 'Cancel Editing' : 'Edit Profile',
            onPressed: () {
              setState(() {
                if (_isEditing) _loadProfile();
                _isEditing = !_isEditing;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _loadProfile();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar & Header Card
              CustomCard(
                gradient: AppColors.elevatedGradient,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.primaryAccent,
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            p.targetJobRole.isNotEmpty
                                ? p.targetJobRole
                                : 'Aspiring Software Engineer',
                            style: const TextStyle(
                                color: AppColors.brightAccent,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600),
                          ),
                          if (p.college.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              p.college,
                              style: const TextStyle(
                                  color: AppColors.secondaryText, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_isEditing) ...[
                // Edit Form Mode
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Edit Profile Details',
                          style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameController,
                        validator: (v) =>
                            Validators.requiredField(v, 'Full name'),
                        decoration:
                            const InputDecoration(labelText: 'Full Name *'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _targetRoleController,
                        decoration: const InputDecoration(
                            labelText: 'Target Career Role'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                      labelText: 'Email'))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: TextFormField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                      labelText: 'Phone'))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: TextFormField(
                                  controller: _collegeController,
                                  decoration: const InputDecoration(
                                      labelText: 'College / University'))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: TextFormField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(
                                      labelText: 'City'))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: TextFormField(
                                  controller: _degreeController,
                                  decoration: const InputDecoration(
                                      labelText: 'Degree (e.g. B.Tech)'))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: TextFormField(
                                  controller: _branchController,
                                  decoration: const InputDecoration(
                                      labelText: 'Branch / Stream'))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: TextFormField(
                                  controller: _semesterController,
                                  decoration: const InputDecoration(
                                      labelText: 'Current Semester'))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: TextFormField(
                                  controller: _gradYearController,
                                  decoration: const InputDecoration(
                                      labelText: 'Graduation Year'))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                          controller: _githubController,
                          decoration: const InputDecoration(
                              labelText: 'GitHub Profile URL')),
                      const SizedBox(height: 10),
                      TextFormField(
                          controller: _linkedinController,
                          decoration: const InputDecoration(
                              labelText: 'LinkedIn Profile URL')),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'About / Bio',
                          hintText:
                              'A brief summary of your technical interests and aspirations...',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48)),
                        icon: const Icon(Icons.check),
                        label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
                        onPressed: _isSaving ? null : _saveProfile,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Read-only Display Mode
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Academic Information',
                          style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildInfoRow('Institution',
                          p.college.isNotEmpty ? p.college : 'Not specified'),
                      _buildInfoRow('Degree & Branch',
                          '${p.degree.isNotEmpty ? p.degree : 'B.Tech'} - ${p.branch.isNotEmpty ? p.branch : 'CSE'}'),
                      _buildInfoRow(
                          'Current Semester',
                          p.currentSemester.isNotEmpty
                              ? p.currentSemester
                              : '7th Semester'),
                      _buildInfoRow(
                          'Graduation Year',
                          p.graduationYear.isNotEmpty
                              ? p.graduationYear
                              : '2026'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contact & Professional Links',
                          style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                          'Email', p.email.isNotEmpty ? p.email : 'None added'),
                      _buildInfoRow(
                          'Phone', p.phone.isNotEmpty ? p.phone : 'None added'),
                      _buildInfoRow('Location',
                          p.city.isNotEmpty ? p.city : 'None added'),
                      if (p.githubUrl.isNotEmpty) ...[
                        const Divider(),
                        InkWell(
                          onTap: () => _launchUrl(p.githubUrl),
                          child: Row(
                            children: [
                              const Icon(Icons.code,
                                  size: 16, color: AppColors.brightAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(p.githubUrl,
                                      style: const TextStyle(
                                          color: AppColors.secondaryAccent,
                                          fontSize: 12,
                                          decoration:
                                              TextDecoration.underline))),
                            ],
                          ),
                        ),
                      ],
                      if (p.linkedinUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _launchUrl(p.linkedinUrl),
                          child: Row(
                            children: [
                              const Icon(Icons.business_center,
                                  size: 16, color: AppColors.brightAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(p.linkedinUrl,
                                      style: const TextStyle(
                                          color: AppColors.secondaryAccent,
                                          fontSize: 12,
                                          decoration:
                                              TextDecoration.underline))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (p.bio.isNotEmpty) ...[
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('About & Objectives',
                            style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          p.bio,
                          style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 13,
                              height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppColors.mutedText, fontSize: 12.5)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
