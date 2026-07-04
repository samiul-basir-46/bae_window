import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class EmptyChatWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  const EmptyChatWidget({
    super.key,
    this.title = 'No messages here yet',
    this.subtitle = 'Start the conversation by typing a message below.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPink.withValues(alpha: 0.15),
                    AppColors.primaryPurple.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.primaryPink.withValues(alpha: 0.2),
                  width: 1.5.w,
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32.sp,
                color: AppColors.primaryPink,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              title,
              style: TextFontStyle.textStyle16cFFFFFFDMSans600,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              style: TextFontStyle.textStyle14c8E8E9FDMSans400,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
