import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class HourglassAnimation extends StatefulWidget {
  final double size;
  final Color color;

  const HourglassAnimation({
    super.key,
    this.size = 30.0,
    this.color = Colors.amberAccent,
  });

  @override
  State<HourglassAnimation> createState() => _HourglassAnimationState();
}

class _HourglassAnimationState extends State<HourglassAnimation> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: Lottie.asset(
          'assets/lottie/sand_loading.json',
          fit: BoxFit.contain,
          delegates: LottieDelegates(
            values: [
              ValueDelegate.color(
                const ['top sand', '**', 'Fill 1'],
                value: widget.color,
              ),
              ValueDelegate.color(
                const ['bottom sand 2', '**', 'Fill 1'],
                value: widget.color,
              ),
              ValueDelegate.strokeColor(
                const ['filler path', '**', 'Stroke 1'],
                value: widget.color,
              ),
              ValueDelegate.color(
                const ['top fill', '**', 'Fill 1'],
                value: widget.color,
              ),
              ValueDelegate.color(
                const ['bottom fill', '**', 'Fill 1'],
                value: widget.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
