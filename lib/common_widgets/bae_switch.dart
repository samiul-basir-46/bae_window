import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class BaeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const BaeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: 46.w,
          height: 26.h,
          child: Stack(
            children: [
              // 1. Inactive State Background (and border)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.5.w,
                  ),
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
              
              // 2. Active State Background (Gradient + Shadow Glow)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                opacity: value ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryPink, AppColors.primaryPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPink.withValues(alpha: 0.25),
                        blurRadius: 4.r,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Sliding Thumb
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.fastOutSlowIn,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: RepaintBoundary(
                    child: Container(
                      width: 18.w,
                      height: 18.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 3.r,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
