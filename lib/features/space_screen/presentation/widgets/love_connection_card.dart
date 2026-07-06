import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:intl/intl.dart';

class LoveConnectionCard extends StatefulWidget {
  final DateTime? anniversaryDate;
  final VoidCallback onTapSelectAnniversary;

  const LoveConnectionCard({
    super.key,
    required this.anniversaryDate,
    required this.onTapSelectAnniversary,
  });

  @override
  State<LoveConnectionCard> createState() => _LoveConnectionCardState();
}

class _LoveConnectionCardState extends State<LoveConnectionCard>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  late AnimationController _heartController;
  late Animation<double> _heartScale;

  late AnimationController _pulseController;
  late Animation<double> _pulseGlow;

  @override
  void initState() {
    super.initState();

    // 1. Floating Animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4.h, end: 4.h).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // 2. Heartbeat Animation (Double-pulse)
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
    )..repeat();

    _pulseGlow = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _heartController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  int get daysLeft {
    if (widget.anniversaryDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var nextAnniv = DateTime(today.year, widget.anniversaryDate!.month, widget.anniversaryDate!.day);
    
    if (nextAnniv.isBefore(today)) {
      nextAnniv = DateTime(today.year + 1, widget.anniversaryDate!.month, widget.anniversaryDate!.day);
    }
    return nextAnniv.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: GestureDetector(
              onTap: widget.onTapSelectAnniversary,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  children: [
                    // Heart & Glow Ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseGlow,
                          builder: (context, child) {
                            return Opacity(
                              opacity: (1.0 - (_pulseController.value * 1.3)).clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: _pulseGlow.value,
                                child: Container(
                                  width: 60.w,
                                  height: 60.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryPink.withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: AppColors.primaryPink.withValues(alpha: 0.2),
                                      width: 1.w,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _heartScale,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _heartScale.value,
                              child: Container(
                                width: 52.w,
                                height: 52.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryPink,
                                      AppColors.primaryPink.withValues(alpha: 0.8),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPink.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.white,
                                  size: 22.sp,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    UIHelper.horizontalSpace(20.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "NEXT ANNIVERSARY",
                            style: GoogleFonts.dmSans(
                              color: AppColors.primaryPink,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          UIHelper.verticalSpace(6.h),
                          if (widget.anniversaryDate == null) ...[
                            Text(
                              "Set Anniversary Date",
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            UIHelper.verticalSpace(4.h),
                            Text(
                              "Tap to choose date 📅",
                              style: GoogleFonts.dmSans(
                                color: Colors.white38,
                                fontSize: 11.sp,
                              ),
                            ),
                          ] else ...[
                            Text(
                              "$daysLeft Days Left",
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            UIHelper.verticalSpace(4.h),
                            Text(
                              DateFormat('MMMM d, yyyy').format(widget.anniversaryDate!),
                              style: GoogleFonts.dmSans(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
