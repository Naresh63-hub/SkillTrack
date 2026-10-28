import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class QuickActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const QuickActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });
}

class QuickActionsBar extends StatelessWidget {
  final List<QuickActionItem> actions;

  const QuickActionsBar({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: actions.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: item.onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (item.color ?? AppColors.brightAccent)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          size: 15,
                          color: item.color ?? AppColors.brightAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
