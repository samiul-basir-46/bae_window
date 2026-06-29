import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class ProfileAvatar extends StatelessWidget {
  final VoidCallback onTap;

  const ProfileAvatar({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 110.w,
            height: 110.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6A82FF), Color(0xFF9868FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 3.w,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 2.h, right: 2.w),
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6E7F), // pink accent
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.softBlack, width: 2.w),
            ),
            child: Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
