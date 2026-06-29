import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class ProfileFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool enabled;
  final Widget? suffixIcon;

  const ProfileFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.enabled = true,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white38,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
          ),
        ),
      ),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1.w,
          ),
        ),
        child: TextField(
          controller: controller,
          enabled: enabled,
          cursorColor: AppColors.primaryPink,
          style: GoogleFonts.dmSans(
            color: enabled ? Colors.white : Colors.white38,
            fontSize: 13.sp,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(color: Colors.white24, fontSize: 13.sp),
            border: InputBorder.none,
            suffixIcon: suffixIcon,
          ),
        ),
      ),
    ],
  );
}
}
