import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/skilltrack_logo.dart';
import '../../../app.dart';
import 'onboarding_screen.dart';

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
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _progressController.forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final hasOnboarded = prefs.getBool('has_onboarded') ?? false;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            hasOnboarded ? const MainNavigationShell() : const OnboardingScreen(),
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
                const SkillTrackLogo(size: 96),
                const SizedBox(height: 24),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.appTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryText,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Progress Bar (Matching design sheet Screen 1)
          Positioned(
            bottom: 48,
            left: 48,
            right: 48,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 5,
                        color: AppColors.border,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _progressAnimation.value,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryAccent,
                                  AppColors.brightAccent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
