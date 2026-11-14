import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SkillTrackLogo extends StatelessWidget {
  final double size;
  final bool showBadge;

  const SkillTrackLogo({
    super.key,
    this.size = 72,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => CustomPaint(
          size: Size(size, size),
          painter: _LightningBoltPainter(),
        ),
      ),
    );

    if (!showBadge) return image;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            blurRadius: size * 0.25,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}

class _LightningBoltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.secondaryAccent,
          AppColors.brightAccent,
          AppColors.primaryAccent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Stylized "S" lightning bolt path matching the SkillTrack brand emblem
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.15, h * 0.05);
    path.lineTo(w * 0.90, h * 0.05);
    path.lineTo(w * 0.48, h * 0.45);
    path.lineTo(w * 0.85, h * 0.45);
    path.lineTo(w * 0.15, h * 0.95);
    path.lineTo(w * 0.38, h * 0.55);
    path.lineTo(w * 0.15, h * 0.55);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
