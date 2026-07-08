import 'package:flutter/material.dart';
import 'dart:math' as math;

class FloatingBubblesBackground extends StatefulWidget {
  final Widget child;
  final Color bubbleColor;

  const FloatingBubblesBackground({
    super.key,
    required this.child,
    this.bubbleColor = const Color(0xFFFF8FB8),
  });

  @override
  State<FloatingBubblesBackground> createState() =>
      _FloatingBubblesBackgroundState();
}

class _FloatingBubblesBackgroundState extends State<FloatingBubblesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Bubble> _bubbles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    final rand = math.Random();
    for (int i = 0; i < 20; i++) {
      _bubbles.add(_Bubble(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        size: 3.0 + rand.nextDouble() * 5.0,
        speed: 0.08 + rand.nextDouble() * 0.12,
        opacity: 0.08 + rand.nextDouble() * 0.18,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BubblesPainter(
              bubbles: _bubbles,
              progress: _controller.value,
              bubbleColor: widget.bubbleColor,
            ),
            child: child,
          );
        },
        child: RepaintBoundary(
          child: widget.child,
        ),
      ),
    );
  }
}

class _Bubble {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  _Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _BubblesPainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double progress;
  final Color bubbleColor;

  _BubblesPainter({
    required this.bubbles,
    required this.progress,
    required this.bubbleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final bubble in bubbles) {
      double currentY = (bubble.y - (bubble.speed * progress)) % 1.0;
      if (currentY < 0) currentY += 1.0;

      final px = bubble.x * size.width;
      final py = currentY * size.height;

      double fade = 1.0;
      if (currentY < 0.2) {
        fade = currentY / 0.2;
      } else if (currentY > 0.8) {
        fade = (1.0 - currentY) / 0.2;
      }

      paint.color = bubbleColor.withValues(alpha: bubble.opacity * fade);
      canvas.drawCircle(Offset(px, py), bubble.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => true;
}
