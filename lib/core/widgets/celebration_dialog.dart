import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CelebrationDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;

  const CelebrationDialog({
    super.key,
    this.title = 'Keep Going!',
    this.subtitle = "You're one step closer to your dream career",
    this.actionLabel = 'Explore More',
    this.onAction,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Keep Going!',
    String subtitle = "You're one step closer to your dream career",
    String actionLabel = 'Explore More',
    VoidCallback? onAction,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CelebrationDialog(
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Golden Trophy with sparkle accents
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFBBF24).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sparkles
                  Positioned(
                    top: 8,
                    left: 12,
                    child: Icon(Icons.star,
                        size: 16,
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.8)),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Icon(Icons.auto_awesome,
                        size: 18,
                        color: AppColors.lightPurple.withValues(alpha: 0.85)),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 20,
                    child: Icon(Icons.star_rounded,
                        size: 14,
                        color:
                            AppColors.gradientHighlight.withValues(alpha: 0.7)),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Icon(Icons.auto_awesome_rounded,
                        size: 14,
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.8)),
                  ),
                  // Golden Trophy
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 72,
                    color: Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onAction?.call();
                },
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
