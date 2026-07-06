import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class SmartAwarenessLayer extends StatelessWidget {
  final String? message;
  final String? icon;

  const SmartAwarenessLayer({
    super.key,
    this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final hasMessage = message != null && message!.isNotEmpty;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: hasMessage
          ? Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.primaryPink.withValues(alpha: 0.2),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null && icon!.isNotEmpty) ...[
                    Text(
                      icon!,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Flexible(
                    child: Text(
                      message!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(height: 0, width: double.infinity),
    );
  }
}
