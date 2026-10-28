import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/skilltrack_logo.dart';
import '../../../core/database/sample_data.dart';
import '../../../app.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _enterApp({bool loadSample = false}) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_onboarded', true);

    if (loadSample) {
      await SampleData.loadDemoData();
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const MainNavigationShell(),
        transitionsBuilder: (context, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _showAuthDialog({required bool isSignUp}) {
    final nameController =
        TextEditingController(text: isSignUp ? '' : 'Priya Sharma');
    final emailController = TextEditingController(
        text: isSignUp ? '' : 'priya.sharma@college.edu');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSignUp ? 'Create Student Profile' : 'Welcome Back',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isSignUp
                    ? 'Start tracking your technical career journey.'
                    : 'Log in to continue where you left off.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Student Name',
                  hintText: 'e.g. Priya Sharma',
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      color: AppColors.secondaryAccent),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'College Email',
                  hintText: 'e.g. student@college.edu',
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.secondaryAccent),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _enterApp(loadSample: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isSignUp ? 'Sign Up' : 'Log In',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Logo & Title (matching Screen 3)
              const Center(
                child: SkillTrackLogo(size: 88),
              ),
              const SizedBox(height: 20),
              const Text(
                AppStrings.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.appTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryText,
                ),
              ),

              const Spacer(),

              // Sign Up Button (Solid Purple)
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _showAuthDialog(isSignUp: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Login Button (Outlined Purple)
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => _showAuthDialog(isSignUp: false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Continue as Guest
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : () => _enterApp(loadSample: true),
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
