import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/home_state.dart';

class RelationshipPulseCard extends StatelessWidget {
  final List<PulseData> data;
  final String partnerName;

  const RelationshipPulseCard({
    super.key,
    required this.data,
    required this.partnerName,
  });

  @override
  Widget build(BuildContext context) {
    // Find max value for scaling the bars
    int maxCount = 1;
    for (var item in data) {
      maxCount = max(maxCount, max(item.userCount, item.partnerCount));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            "RELATIONSHIP PULSE",
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
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1.w,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "This Week",
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              UIHelper.verticalSpace(4.h),
              Text(
                "Snaps, drawings, voice, mood & pulse",
                style: GoogleFonts.dmSans(
                  color: Colors.white38,
                  fontSize: 11.sp,
                ),
              ),
              UIHelper.verticalSpace(24.h),
              // Chart Bars
              SizedBox(
                height: 100.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.map((item) {
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildBar(item.userCount, maxCount,
                                    AppColors.primaryPurple),
                                SizedBox(width: 4.w),
                                _buildBar(item.partnerCount, maxCount,
                                    AppColors.primaryPink),
                              ],
                            ),
                          ),
                          UIHelper.verticalSpace(8.h),
                          Text(
                            item.day,
                            style: GoogleFonts.dmSans(
                              color: Colors.white38,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              UIHelper.verticalSpace(16.h),
              // Legend
              Row(
                children: [
                  _buildLegendItem("You", AppColors.primaryPurple),
                  SizedBox(width: 16.w),
                  _buildLegendItem(
                    partnerName.trim().isEmpty ? "Partner" : partnerName,
                    AppColors.primaryPink,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBar(int count, int maxCount, Color color) {
    final double pct = count / maxCount;
    return Container(
      width: 8.w,
      height: max(6.h, 75.h * pct),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: Colors.white54,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}
