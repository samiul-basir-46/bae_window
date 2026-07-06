import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

class TaskProgressBar extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;

  const TaskProgressBar({
    super.key,
    required this.progress,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Shared Progress",
                  style: GoogleFonts.dmSans(
                      color: Colors.white70,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "$completed/$total Completed (${(progress * 100).toInt()}%)",
                  style: GoogleFonts.dmSans(
                      color: Colors.blueAccent,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            UIHelper.verticalSpace(10.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6.h,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
