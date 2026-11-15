import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/skilltrack_logo.dart';
import '../../../models/student_profile.dart';
import '../../../repositories/profile_repository.dart';
import '../../../services/supabase_auth_service.dart';
import '../../../services/navigation_state_service.dart';
import '../../../app.dart';
import '../../auth/screens/auth_screen.dart';
import 'onboarding_screen.dart';
import 'student_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    // Snappy, modern startup animation (400ms instead of 1800ms)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    _progressController.forward();
    _fastBootAndNavigate();
  }

  Future<void> _fastBootAndNavigate() async {
    // Run all database, preferences, and auth checks concurrently
    final results = await Future.wait([
      ProfileRepository().getProfile(),
      SharedPreferences.getInstance(),
      NavigationStateService.instance.getActiveTab(),
      NavigationStateService.instance.getActiveRoute(),
      Future.delayed(const Duration(milliseconds: kIsWeb ? 200 : 350)),
    ]);

    final profile = results[0] as StudentProfile;
    final prefs = results[1] as SharedPreferences;
    final savedTab = results[2] as int;
    final savedRoute = results[3] as String?;

    final hasValidProfile = profile.name.trim().isNotEmpty;
    final hasOnboarded = prefs.getBool('has_onboarded') ?? false;

    final authService = SupabaseAuthService.instance;
    final isAuth = authService.isAuthenticated;
    final isGuest = prefs.getBool('is_guest_mode') ?? false;

    if (!mounted) return;

    Widget target;
    if (isAuth || isGuest) {
      if (hasValidProfile) {
        target = MainNavigationShell(
          initialIndex: savedTab,
          initialRoute: savedRoute,
        );
      } else {
        target = const StudentSetupScreen();
      }
    } else if (!hasOnboarded) {
      target = const OnboardingScreen();
    } else {
      target = const AuthScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: Stack(
        children: [
          // Ambient purple background glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryAccent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brightAccent.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Animated Logo Badge
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAccent.withValues(alpha: 0.35),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primaryAccent.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const SkillTrackLogo(size: 80),
                ),
                const SizedBox(height: 28),

                // Application Title
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline matching design sheet
                const Text(
                  'Build Skills. Track Progress. Get Placement Ready.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Loading Progress Bar
          Positioned(
            bottom: 48,
            left: 48,
            right: 48,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value,
                        minHeight: 5,
                        backgroundColor:
                            AppColors.primaryAccent.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.brightAccent),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'INITIALIZING SECURE LOCAL STORAGE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
