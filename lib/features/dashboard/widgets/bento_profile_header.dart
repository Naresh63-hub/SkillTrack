import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/student_profile.dart';

class BentoProfileHeader extends StatefulWidget {
  final StudentProfile? profile;
  final int streakDays;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onStreakTap;
  final VoidCallback? onRoleTap;
  final VoidCallback? onNotificationTap;

  const BentoProfileHeader({
    super.key,
    required this.profile,
    required this.streakDays,
    this.onAvatarTap,
    this.onStreakTap,
    this.onRoleTap,
    this.onNotificationTap,
  });

  @override
  State<BentoProfileHeader> createState() => _BentoProfileHeaderState();
}

class _BentoProfileHeaderState extends State<BentoProfileHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final name = (p != null && p.name.trim().isNotEmpty) ? p.name.trim() : 'Student';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final college = (p != null && p.college.trim().isNotEmpty) ? p.college.trim() : 'Tech Institute';
    final targetRole = (p != null && p.targetJobRole.trim().isNotEmpty)
        ? p.targetJobRole.trim()
        : 'Software Engineer';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              InkWell(
                onTap: widget.onAvatarTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & College
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      college,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Animated Pulsing Flame Streak Badge
              ScaleTransition(
                scale: _pulseScale,
                child: InkWell(
                  onTap: widget.onStreakTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFEF3C7),
                          const Color(0xFFFDE68A).withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.streakDays} Day${widget.streakDays == 1 ? "" : "s"}',
                          style: const TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.onNotificationTap != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: widget.onNotificationTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryCard,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.lightPurple,
                      size: 17,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Target Job Role Pill
          InkWell(
            onTap: widget.onRoleTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded,
                      size: 14, color: AppColors.primaryPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Target: $targetRole',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 11, color: AppColors.mutedText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
