import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/skilltrack_logo.dart';
import '../../../models/student_profile.dart';
import '../../../repositories/profile_repository.dart';
import '../../../app.dart';

class StudentSetupScreen extends StatefulWidget {
  const StudentSetupScreen({super.key});

  @override
  State<StudentSetupScreen> createState() => _StudentSetupScreenState();
}

class _StudentSetupScreenState extends State<StudentSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileRepository _profileRepo = ProfileRepository();

  final _nameController = TextEditingController();
  final _collegeController = TextEditingController();
  final _branchController = TextEditingController();
  final _targetRoleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _degree = 'B.Tech';
  String _semester = '6th Semester';
  String _gradYear = '2026';
  bool _isSaving = false;

  final List<String> _degreeOptions = [
    'B.Tech',
    'B.E.',
    'BCA',
    'MCA',
    'B.Sc Computer Science',
    'M.Tech',
    'Other',
  ];

  final List<String> _semesterOptions = [
    '1st Semester',
    '2nd Semester',
    '3rd Semester',
    '4th Semester',
    '5th Semester',
    '6th Semester',
    '7th Semester',
    '8th Semester',
    'Graduated',
  ];

  final List<String> _gradYearOptions = [
    '2024',
    '2025',
    '2026',
    '2027',
    '2028',
    '2029',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    _branchController.dispose();
    _targetRoleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final profile = StudentProfile(
        name: _nameController.text.trim(),
        college: _collegeController.text.trim(),
        degree: _degree,
        branch: _branchController.text.trim().isNotEmpty
            ? _branchController.text.trim()
            : 'Computer Science',
        currentSemester: _semester,
        graduationYear: _gradYear,
        targetJobRole: _targetRoleController.text.trim().isNotEmpty
            ? _targetRoleController.text.trim()
            : 'Software Developer',
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      await _profileRepo.saveProfile(profile);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_onboarded', true);
      await prefs.setBool('has_setup_profile', true);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, anim, secAnim) => const MainNavigationShell(),
          transitionsBuilder: (context, anim, secAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                // Logo & Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryAccent.withValues(alpha: 0.2),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const SkillTrackLogo(size: 54),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Set Up Your Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your student details to customize your progress tracking & resume.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Form Card
                CustomCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      const Text(
                        'Full Name *',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.primaryText),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Rahul Sharma',
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              color: AppColors.primaryAccent),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // College Name
                      const Text(
                        'College / University *',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _collegeController,
                        style: const TextStyle(color: AppColors.primaryText),
                        decoration: const InputDecoration(
                          hintText: 'e.g. National Institute of Technology',
                          prefixIcon: Icon(Icons.school_outlined,
                              color: AppColors.brightAccent),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your college name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Degree & Branch Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Degree',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _degree,
                                  dropdownColor: AppColors.cardBackground,
                                  style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 13),
                                  items: _degreeOptions.map((deg) {
                                    return DropdownMenuItem(
                                        value: deg, child: Text(deg));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _degree = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Branch / Major',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _branchController,
                                  style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 13),
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Computer Science',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Semester & Grad Year Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Semester',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _semester,
                                  dropdownColor: AppColors.cardBackground,
                                  style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 13),
                                  items: _semesterOptions.map((sem) {
                                    return DropdownMenuItem(
                                        value: sem, child: Text(sem));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _semester = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Graduation Year',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _gradYear,
                                  dropdownColor: AppColors.cardBackground,
                                  style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 13),
                                  items: _gradYearOptions.map((yr) {
                                    return DropdownMenuItem(
                                        value: yr, child: Text(yr));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _gradYear = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Target Job Role
                      const Text(
                        'Target Job Role',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _targetRoleController,
                        style: const TextStyle(color: AppColors.primaryText),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Software Developer / SDE',
                          prefixIcon: Icon(Icons.work_outline_rounded,
                              color: AppColors.secondaryAccent),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Optional Contact Fields Accordion
                      Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          title: const Text(
                            '+ Add Optional Email & Phone',
                            style: TextStyle(
                              color: AppColors.secondaryAccent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style:
                                  const TextStyle(color: AppColors.primaryText),
                              decoration: const InputDecoration(
                                labelText: 'Email (Optional)',
                                prefixIcon: Icon(Icons.email_outlined,
                                    color: AppColors.mutedText),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style:
                                  const TextStyle(color: AppColors.primaryText),
                              decoration: const InputDecoration(
                                labelText: 'Phone Number (Optional)',
                                prefixIcon: Icon(Icons.phone_outlined,
                                    color: AppColors.mutedText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryAccent,
                          AppColors.brightAccent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryAccent.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue to Dashboard',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
