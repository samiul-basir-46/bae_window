import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class UploadProgressWidget extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final VoidCallback? onCancel;

  const UploadProgressWidget({
    super.key,
    required this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.navBgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32.r,
            height: 32.r,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3.w,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Uploading attachment...',
                  style: TextFontStyle.textStyle12c8E8E9FDMSans600.copyWith(
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$percent% completed',
                  style: TextFontStyle.textStyle10c888888DMSans600.copyWith(
                    color: AppColors.c8E8E9F,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          if (onCancel != null)
            IconButton(
              onPressed: onCancel,
              icon: Icon(
                Icons.cancel_outlined,
                size: 20.sp,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
