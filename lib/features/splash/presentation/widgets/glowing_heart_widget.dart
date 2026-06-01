import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class GlowingHeartWidget extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final Animation<double> glowIntensityAnimation;
  final AnimationController pulseController;

  const GlowingHeartWidget({
    super.key,
    required this.fadeAnimation,
    required this.scaleAnimation,
    required this.glowIntensityAnimation,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: pulseController,
              builder: (context, child) {
                return Container(
                  width: 140.w,
                  height: 140.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cFFB3C6.withValues(
                          alpha: 0.28 * glowIntensityAnimation.value,
                        ),
                        blurRadius:
                            42.r + (16.r * glowIntensityAnimation.value),
                        spreadRadius:
                            2.w + (6.w * glowIntensityAnimation.value),
                      )
                    ],
                  ),
                );
              },
            ),
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [
                    AppColors.cFFB3C6,
                    AppColors.cFFC6FF,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: Icon(
                Icons.favorite_rounded,
                size: 120.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
