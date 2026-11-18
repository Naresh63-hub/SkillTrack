import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            child: BouncyQuickActionPill(item: item),
          );
        }).toList(),
      ),
    );
  }
}

class BouncyQuickActionPill extends StatefulWidget {
  final QuickActionItem item;

  const BouncyQuickActionPill({super.key, required this.item});

  @override
  State<BouncyQuickActionPill> createState() => _BouncyQuickActionPillState();
}

class _BouncyQuickActionPillState extends State<BouncyQuickActionPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    HapticFeedback.lightImpact();
    widget.item.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final actionColor = widget.item.color ?? AppColors.lightPurple;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10.5),
          decoration: BoxDecoration(
            color: AppColors.secondaryCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: actionColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.item.icon,
                  size: 16,
                  color: actionColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.item.label,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
