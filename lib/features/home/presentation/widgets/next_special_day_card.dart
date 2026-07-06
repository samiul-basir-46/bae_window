import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/home_state.dart';

class NextSpecialDayCard extends StatefulWidget {
  final SpecialDay specialDay;

  const NextSpecialDayCard({super.key, required this.specialDay});

  @override
  State<NextSpecialDayCard> createState() => _NextSpecialDayCardState();
}

class _NextSpecialDayCardState extends State<NextSpecialDayCard> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeRemaining();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    final now = DateTime.now();
    final difference = widget.specialDay.targetDate.difference(now);
    _timeRemaining = difference.isNegative ? Duration.zero : difference;
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;

    // Formatting date string, e.g., "August 14, 2024"
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final dateStr = "${months[widget.specialDay.targetDate.month - 1]} ${widget.specialDay.targetDate.day}, ${widget.specialDay.targetDate.year}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            "NEXT SPECIAL DAY",
            style: GoogleFonts.dmSans(
              color: Colors.white38,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.primaryPink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: AppColors.primaryPink.withValues(alpha: 0.15),
              width: 1.w,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "🎉",
                      style: TextStyle(fontSize: 18.sp),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.specialDay.title,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        UIHelper.verticalSpace(2.h),
                        Text(
                          dateStr,
                          style: GoogleFonts.dmSans(
                            color: Colors.white38,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              UIHelper.verticalSpace(20.h),
              RepaintBoundary(
                child: Row(
                  children: [
                    _buildCountdownBox(days.toString(), "Days"),
                    SizedBox(width: 12.w),
                    _buildCountdownBox(hours.toString().padLeft(2, '0'), "Hours"),
                    SizedBox(width: 12.w),
                    _buildCountdownBox(minutes.toString().padLeft(2, '0'), "Mins"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1.w,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                color: AppColors.primaryPink,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            UIHelper.verticalSpace(2.h),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white38,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
