import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFA4C8BF), Color(0xFF4E8C79), Color(0xFF064939)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _OrganicPattern(_controller.value))),
            Positioned(
              top: -100 + _controller.value * 30,
              right: -80,
              child: _orb(230, const Color(0xFFB8DF9B).withValues(alpha: .22)),
            ),
            Positioned(
              bottom: -120 - _controller.value * 24,
              left: -70,
              child: _orb(270, const Color(0xFF002D23).withValues(alpha: .2)),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _OrganicPattern extends CustomPainter {
  _OrganicPattern(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = Colors.white.withValues(alpha: .15);
    final leaf = Paint()
      ..color = Colors.white.withValues(alpha: .09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 100; i++) {
      final x = (i * 83.0) % size.width;
      final y = ((i * 139.0) + progress * 32) % size.height;
      canvas.drawCircle(Offset(x, y), i % 4 == 0 ? 2.2 : .9, dot);
    }
    for (var i = 0; i < 20; i++) {
      final center = Offset((i * 173.0 + 48) % size.width, (i * 109.0 + 38) % size.height);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(sin(i + progress * pi) * .45);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 18, height: 34), leaf);
      canvas.drawLine(const Offset(0, -12), const Offset(0, 12), leaf);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicPattern oldDelegate) => oldDelegate.progress != progress;
}
