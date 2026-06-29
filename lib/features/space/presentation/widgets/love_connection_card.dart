import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

class LoveConnectionCard extends StatefulWidget {
  final int daysTogether;
  final String mood;

  const LoveConnectionCard({
    super.key,
    required this.daysTogether,
    required this.mood,
  });

  @override
  State<LoveConnectionCard> createState() => _LoveConnectionCardState();
}

class _LoveConnectionCardState extends State<LoveConnectionCard> with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  late final AnimationController _heartController;
  late final Animation<double> _heartScale;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseGlow;

  @override
  void initState() {
    super.initState();

    // 1. Floating Animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5.h, end: 5.h).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // 2. Heartbeat Animation
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.06).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.22).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.22, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 45,
      ),
    ]).animate(_heartController);

    // 3. Glowing ring pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseGlow = Tween<double>(begin: 8.r, end: 20.r).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _heartController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.w,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  color: Colors.white.withValues(alpha: 0.02),
                  child: Row(
                    children: [
                      // Heart & Glow Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseGlow,
                            builder: (context, child) {
                              return Container(
                                width: 84.w,
                                height: 84.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryPink.withValues(alpha: 0.25),
                                    width: 3.w,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPink.withValues(alpha: 0.15),
                                      blurRadius: _pulseGlow.value,
                                      spreadRadius: 2.r,
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                          ScaleTransition(
                            scale: _heartScale,
                            child: Icon(
                              Icons.favorite_rounded,
                              color: AppColors.primaryPink,
                              size: 38.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 24.w),

                      // Anniversary info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Anniversary Countdown",
                              style: GoogleFonts.dmSans(
                                color: Colors.white38,
                                fontSize: 10.sp,
                                letterSpacing: 0.5,
                              ),
                            ),
                            UIHelper.verticalSpace(4.h),
                            Text(
                              "${widget.daysTogether} Days Together",
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            UIHelper.verticalSpace(4.h),
                            Text(
                              "Mood: ${widget.mood}",
                              style: GoogleFonts.dmSans(
                                color: AppColors.primaryPurple,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
