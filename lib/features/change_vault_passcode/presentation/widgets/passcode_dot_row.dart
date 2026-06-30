import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

class PasscodeDotRow extends StatelessWidget {
  final int filledCount;
  final String? error;

  const PasscodeDotRow({
    super.key,
    required this.filledCount,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final filled = index < filledCount;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              margin: EdgeInsets.symmetric(horizontal: 10.w),
              width: 14.w,
              height: 14.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? (error != null ? Colors.redAccent : AppColors.primaryPink)
                    : Colors.transparent,
                border: Border.all(
                  color: filled
                      ? (error != null ? Colors.redAccent : AppColors.primaryPink)
                      : Colors.white24,
                  width: 2.w,
                ),
              ),
            );
          }),
        ),
        if (error != null) ...[
          UIHelper.verticalSpace(10.h),
          Text(
            error!,
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 11.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
