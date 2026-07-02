import 'package:flutter/material.dart';
import 'dart:math' as math;

class HourglassAnimation extends StatefulWidget {
  final double size;
  final Color color;

  const HourglassAnimation({
    super.key,
    this.size = 20.0,
    this.color = Colors.amberAccent,
  });

  @override
  State<HourglassAnimation> createState() => _HourglassAnimationState();
}

class _HourglassAnimationState extends State<HourglassAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _sandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // 0.0 to 0.8: sand flows down
    // 0.8 to 1.0: hourglass flips 180 degrees
    _sandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.linear),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeInOutBack),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _HourglassPainter(
                progress: _sandAnimation.value,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HourglassPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;

  _HourglassPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintFrame = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paintSand = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Draw the glass frame (triangular top and bottom meeting in the neck)
    final pathFrame = Path()
      ..moveTo(w * 0.15, h * 0.1)
      ..lineTo(w * 0.85, h * 0.1)
      ..lineTo(w * 0.55, h * 0.5) // neck top
      ..lineTo(w * 0.85, h * 0.9)
      ..lineTo(w * 0.15, h * 0.9)
      ..lineTo(w * 0.45, h * 0.5) // neck bottom
      ..close();

    canvas.drawPath(pathFrame, paintFrame);

    // Draw top sand (shrinking)
    if (progress < 1.0) {
      final topY = h * 0.1 + (h * 0.4 * progress);
      final pathTopSand = Path()
        ..moveTo(w * 0.15 + (w * 0.3 * progress), topY)
        ..lineTo(w * 0.85 - (w * 0.3 * progress), topY)
        ..lineTo(w * 0.55, h * 0.5)
        ..lineTo(w * 0.45, h * 0.5)
        ..close();
      canvas.drawPath(pathTopSand, paintSand);
    }

    // Draw falling sand stream (flowing down from neck to bottom)
    if (progress > 0.0 && progress < 0.9) {
      final pathStream = Path()
        ..moveTo(w * 0.48, h * 0.5)
        ..lineTo(w * 0.52, h * 0.5)
        ..lineTo(w * 0.52, h * 0.9)
        ..lineTo(w * 0.48, h * 0.9)
        ..close();
      canvas.drawPath(pathStream, paintSand);
    }

    // Draw bottom sand (growing)
    if (progress > 0.0) {
      final bottomY = h * 0.9 - (h * 0.4 * progress);
      final pathBottomSand = Path()
        ..moveTo(w * 0.5, h * 0.5 + (h * 0.4 * (1.0 - progress)))
        ..lineTo(w * 0.85 - (w * 0.35 * (1.0 - progress)), h * 0.9)
        ..lineTo(w * 0.15 + (w * 0.35 * (1.0 - progress)), h * 0.9)
        ..close();
      canvas.drawPath(pathBottomSand, paintSand);
    }
  }

  @override
  bool overrideMaxSimultaneousCaptures() => false;

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
