import 'dart:math' as math;
import 'package:flutter/material.dart';

class BaeLoader extends StatefulWidget {
  final bool isFullScreen;
  final double size;

  const BaeLoader({
    super.key,
    this.isFullScreen = true,
    this.size = 24.0,
  });

  @override
  State<BaeLoader> createState() => _BaeLoaderState();
}

class _BaeLoaderState extends State<BaeLoader> with TickerProviderStateMixin {
  late final AnimationController _heartController;
  late final AnimationController _orbitController;
  late final AnimationController _ringControllerA;
  late final AnimationController _ringControllerB;

  late final Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.95), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.12), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 45),
    ]).animate(_heartController);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _ringControllerA = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _ringControllerB = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _ringControllerB.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    _orbitController.dispose();
    _ringControllerA.dispose();
    _ringControllerB.dispose();
    super.dispose();
  }

  Widget _buildRing(AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        final scale = 0.6 + (0.55 * t);
        final opacity = (1 - t).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity * 0.9,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF8FB8).withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrbitDot({
    required double phaseOffsetDegrees,
    required List<Color> colors,
  }) {
    return AnimatedBuilder(
      animation: _orbitController,
      builder: (context, child) {
        final angle = (_orbitController.value * 2 * math.pi) +
            (phaseOffsetDegrees * math.pi / 180);
        const radius = 50.0;
        final dx = radius * math.cos(angle);
        final dy = radius * math.sin(angle);
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loaderContent = SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildRing(_ringControllerA),
          _buildRing(_ringControllerB),
          _buildOrbitDot(
            phaseOffsetDegrees: 0,
            colors: const [Color(0xFFFF8FB8), Color(0xFFD94E98)],
          ),
          _buildOrbitDot(
            phaseOffsetDegrees: 180,
            colors: const [Color(0xFFB79CF0), Color(0xFF7F77DD)],
          ),
          ScaleTransition(
            scale: _heartScale,
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFF8FB8),
              size: 28,
            ),
          ),
        ],
      ),
    );

    if (!widget.isFullScreen) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: FittedBox(
          fit: BoxFit.contain,
          child: loaderContent,
        ),
      );
    }

    return Center(
      child: loaderContent,
    );
  }
}
