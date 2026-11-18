import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class DynamicGradientProgressBar extends StatelessWidget {
  final double percentage;
  final double height;
  final bool showLabel;
  final bool showMasteredBadge;

  const DynamicGradientProgressBar({
    super.key,
    required this.percentage,
    this.height = 7.0,
    this.showLabel = true,
    this.showMasteredBadge = true,
  });

  LinearGradient get _dynamicGradient {
    final clamped = percentage.clamp(0.0, 100.0);
    if (clamped >= 80.0) {
      return const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)], // Emerald
      );
    } else if (clamped >= 40.0) {
      return const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)], // Purple to Fuchsia
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)], // Blue to Violet
      );
    }
  }

  Color get _primaryColor {
    final clamped = percentage.clamp(0.0, 100.0);
    if (clamped >= 80.0) return const Color(0xFF059669);
    if (clamped >= 40.0) return const Color(0xFF8B5CF6);
    return const Color(0xFF3B82F6);
  }

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0.0, 100.0);
    final isMastered = clamped >= 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showMasteredBadge && isMastered)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    'Mastered ✨',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              Text(
                '${clamped.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
        ],
        Stack(
          children: [
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (clamped / 100.0).clamp(0.001, 1.0),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: _dynamicGradient,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
