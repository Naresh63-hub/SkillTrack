import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomProgressBar extends StatelessWidget {
  final double percentage; // 0.0 to 100.0
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final bool showLabel;
  final String? labelText;

  const CustomProgressBar({
    super.key,
    required this.percentage,
    this.height = 8,
    this.color,
    this.backgroundColor,
    this.showLabel = false,
    this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0.0, 100.0);
    final ratio = clamped / 100.0;
    final barColor = color ?? AppColors.brightAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (labelText != null)
                Text(
                  labelText!,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Text(
                '${clamped.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: barColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * ratio,
                    height: height,
                    decoration: BoxDecoration(
                      color: barColor,
                      gradient: color == null ? AppColors.accentGradient : null,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
