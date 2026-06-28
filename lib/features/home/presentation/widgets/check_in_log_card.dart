import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/home_state.dart';

class CheckInLogCard extends StatelessWidget {
  final List<CheckInLog> logs;

  const CheckInLogCard({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            "CHECK-IN LOG",
            style: GoogleFonts.dmSans(
              color: Colors.white38,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1.w,
                ),
              ),
              child: Column(
                children: List.generate(logs.length, (index) {
                  final log = logs[index];
                  return Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38.w,
                            height: 38.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                                width: 1.w,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              log.emoji,
                              style: TextStyle(fontSize: 20.sp),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.user,
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                UIHelper.verticalSpace(2.h),
                                Text(
                                  log.time,
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white38,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            log.mood,
                            style: GoogleFonts.dmSans(
                              color: Colors.white70,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (index < logs.length - 1) ...[
                        Divider(
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 24.h,
                          thickness: 1.w,
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
