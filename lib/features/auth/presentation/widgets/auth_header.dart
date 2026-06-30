import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

class AuthHeader extends StatelessWidget {
  final IconData logoIcon;
  final String eyebrow;
  final String headline;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.logoIcon,
    required this.eyebrow,
    required this.headline,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo Mark
        Container(
          width: 52.w,
          height: 52.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF8FB8), Color(0xFFD94E98), Color(0xFFB03085)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB03085).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Icon(logoIcon, color: Colors.white, size: 26.sp),
          ),
        ),
        UIHelper.verticalSpace(20.h),
        // Eyebrow
        Text(
          eyebrow.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFE060A0),
            letterSpacing: 2,
          ),
        ),
        UIHelper.verticalSpace(6.h),
        // Headline
        Text(
          headline,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.25,
          ),
        ),
        UIHelper.verticalSpace(8.h),
        // Subtitle
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13.sp,
            color: const Color(0xFF6B6B80),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
