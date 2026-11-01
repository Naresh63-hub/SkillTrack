import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../placement/screens/coding_prep_screen.dart';
import '../../placement/screens/aptitude_prep_screen.dart';
import '../../placement/screens/interview_prep_screen.dart';
import '../../placement/screens/core_cs_screen.dart';

class PlacementPrepModulesSection extends StatelessWidget {
  final VoidCallback onOpenPlacementHub;
  final VoidCallback? onRefresh;

  const PlacementPrepModulesSection({
    super.key,
    required this.onOpenPlacementHub,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final modules = [
      _ModuleItem(
        title: 'Coding Practice',
        subtitle: 'DSA & Algorithms',
        icon: Icons.terminal_rounded,
        color: AppColors.primaryPurple,
        onTap: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(builder: (ctx) => const CodingPrepScreen()),
              )
              .then((_) => onRefresh?.call());
        },
      ),
      _ModuleItem(
        title: 'Aptitude Prep',
        subtitle: 'Quant & Logical',
        icon: Icons.calculate_rounded,
        color: AppColors.gradientHighlight,
        onTap: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(builder: (ctx) => const AptitudePrepScreen()),
              )
              .then((_) => onRefresh?.call());
        },
      ),
      _ModuleItem(
        title: 'Interview Prep',
        subtitle: 'HR & Tech Questions',
        icon: Icons.record_voice_over_rounded,
        color: AppColors.lightPurple,
        onTap: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                    builder: (ctx) => const InterviewPrepScreen()),
              )
              .then((_) => onRefresh?.call());
        },
      ),
      _ModuleItem(
        title: 'Core CS Subjects',
        subtitle: 'OS, DBMS, CN, OOP',
        icon: Icons.storage_rounded,
        color: const Color(0xFFC084FC),
        onTap: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(builder: (ctx) => const CoreCsScreen()),
              )
              .then((_) => onRefresh?.call());
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Placement Preparation',
          actionText: 'Open Hub',
          onAction: onOpenPlacementHub,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 550 ? 4 : 2;
            final aspectRatio = constraints.maxWidth > 550 ? 1.6 : 1.35;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: aspectRatio,
              ),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final mod = modules[index];
                return CustomCard(
                  onTap: mod.onTap,
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(14),
                  borderRadius: 20,
                  backgroundColor: AppColors.cardBackground,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: mod.color.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: mod.color.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Icon(mod.icon, color: mod.color, size: 18),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppColors.mutedText.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mod.title,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mod.subtitle,
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 10.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ModuleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
