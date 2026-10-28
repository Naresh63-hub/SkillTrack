import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final double borderRadius;
  final Gradient? gradient;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius = 14,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? AppColors.cardBackground)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: AppColors.border, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            child: cardContent,
          ),
        ),
      );
    }

    return Padding(
      padding: margin,
      child: cardContent,
    );
  }
}
