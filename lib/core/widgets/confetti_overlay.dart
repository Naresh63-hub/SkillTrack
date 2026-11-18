import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;
  double opacity;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    this.opacity = 1.0,
  });
}

class ConfettiOverlay {
  static void show(BuildContext context) {
    HapticFeedback.heavyImpact();
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (ctx) => _ConfettiAnimationWidget(
        onFinished: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _ConfettiAnimationWidget extends StatefulWidget {
  final VoidCallback onFinished;

  const _ConfettiAnimationWidget({required this.onFinished});

  @override
  State<_ConfettiAnimationWidget> createState() =>
      _ConfettiAnimationWidgetState();
}

class _ConfettiAnimationWidgetState extends State<_ConfettiAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  static const List<Color> _palette = [
    Color(0xFF7C3AED), // Purple
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Light Purple
    Color(0xFFFFD700), // Gold
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addListener(() {
        _updateParticles();
        setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initParticles();
      _controller.forward().then((_) => widget.onFinished());
    });
  }

  void _initParticles() {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;
    final startY = size.height * 0.35;

    for (int i = 0; i < 75; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 4.0 + _random.nextDouble() * 8.0;
      _particles.add(
        ConfettiParticle(
          x: centerX + (_random.nextDouble() - 0.5) * 80,
          y: startY + (_random.nextDouble() - 0.5) * 40,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 4.0, // Initial upward burst
          size: 6.0 + _random.nextDouble() * 8.0,
          color: _palette[_random.nextInt(_palette.length)],
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.25,
        ),
      );
    }
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.22; // Gravity
      p.vx *= 0.985; // Drag
      p.rotation += p.rotationSpeed;
      if (_controller.value > 0.6) {
        p.opacity = ((1.0 - _controller.value) / 0.4).clamp(0.0, 1.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(particles: _particles),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.opacity <= 0.0) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      final r = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size * 0.6,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
