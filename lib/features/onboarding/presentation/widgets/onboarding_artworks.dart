import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Slide1Artwork extends StatefulWidget {
  const Slide1Artwork({super.key});

  @override
  State<Slide1Artwork> createState() => _Slide1ArtworkState();
}

class _Slide1ArtworkState extends State<Slide1Artwork> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _glowAnimation = Tween<double>(begin: 12.r, end: 32.r).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 170.w,
        height: 310.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32.r),
          border: Border.all(color: const Color(0xFF2C2C35), width: 4.w),
          color: const Color(0xFF18181C),
        ),
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        child: Column(
          children: [
            Container(
              width: 50.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C35),
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            SizedBox(height: 36.h),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 110.w,
                    height: 110.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFB7CE),
                          Color(0xFFE295B5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB7CE).withValues(alpha: 0.35),
                          blurRadius: _glowAnimation.value,
                          spreadRadius: 1.w,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 28.sp,
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            width: 60.w,
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            width: 40.w,
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) => Container(
                width: 20.w,
                height: 20.h,
                decoration: const BoxDecoration(
                  color: Color(0xFF2C2C35),
                  shape: BoxShape.circle,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class Slide2Artwork extends StatefulWidget {
  const Slide2Artwork({super.key});

  @override
  State<Slide2Artwork> createState() => _Slide2ArtworkState();
}

class _Slide2ArtworkState extends State<Slide2Artwork> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _positionAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260.w,
        height: 180.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 45.w,
              right: 45.w,
              child: Container(
                height: 3.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFB7CE).withValues(alpha: 0.2),
                      const Color(0xFFFFB7CE).withValues(alpha: 0.5),
                      const Color(0xFFFFB7CE).withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Align(
                  alignment: Alignment(_positionAnimation.value, 0.0),
                  child: Container(
                    width: 14.w,
                    height: 14.h,
                    margin: EdgeInsets.symmetric(horizontal: 48.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFB7CE),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB7CE).withValues(alpha: 0.8),
                          blurRadius: 12.r,
                          spreadRadius: 2.w,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              child: _buildAvatar(
                icon: Icons.person_rounded,
                borderColor: const Color(0xFFFFB7CE),
                label: "Bae 1",
              ),
            ),
            Positioned(
              right: 0,
              child: _buildAvatar(
                icon: Icons.person_3_rounded,
                borderColor: const Color(0xFFC8B3FF),
                label: "Bae 2",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required IconData icon,
    required Color borderColor,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60.w,
          height: 60.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1C1C22),
            border: Border.all(color: borderColor, width: 2.w),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.2),
                blurRadius: 10.r,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.9),
            size: 26.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF8E8E9F),
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class Slide3Artwork extends StatefulWidget {
  const Slide3Artwork({super.key});

  @override
  State<Slide3Artwork> createState() => _Slide3ArtworkState();
}

class _Slide3ArtworkState extends State<Slide3Artwork> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glowPulse = Tween<double>(begin: 0.4, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 180.w,
                height: 180.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFB7CE).withValues(alpha: 0.16 * _glowPulse.value),
                      const Color(0xFFC8B3FF).withValues(alpha: 0.08 * _glowPulse.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          Container(
            width: 110.w,
            height: 110.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB7CE).withValues(alpha: 0.15),
                  blurRadius: 20.r,
                  spreadRadius: 2.w,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.shield_rounded,
                  color: const Color(0xFF2C2C3A),
                  size: 68.sp,
                ),
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: [
                        Color(0xFFFFB7CE),
                        Color(0xFFC8B3FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 32.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
