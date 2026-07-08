import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class CustomExitDialog extends StatelessWidget {
  const CustomExitDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        child: CustomExitDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
      decoration: BoxDecoration(
        color: AppColors.navBgColor,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24.r,
            spreadRadius: 4.r,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Elegant glowing circular icon container
          Container(
            width: 72.w,
            height: 72.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPink.withValues(alpha: 0.15),
                  AppColors.primaryPurple.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.primaryPink.withValues(alpha: 0.3),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPink.withValues(alpha: 0.2),
                  blurRadius: 16.r,
                  spreadRadius: 2.r,
                ),
              ],
            ),
            child: Icon(
              Icons.logout_rounded,
              color: AppColors.primaryPink,
              size: 32.sp,
            ),
          ),
          SizedBox(height: 24.h),

          // Dialog Title
          Text(
            "Exit App",
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12.h),

          // Dialog Description
          Text(
            "Are you sure you want to close Bae Window?",
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: Colors.white60,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 32.h),

          // Action Buttons Row
          Row(
            children: [
              // Cancel/Stay Button (Soft background / Text style)
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    height: 48.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 1.w,
                      ),
                    ),
                    child: Text(
                      "Stay",
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Confirm/Exit Button (Beautiful Pink/Purple gradient)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (Platform.isAndroid) {
                      SystemNavigator.pop();
                    } else if (Platform.isIOS) {
                      exit(0);
                    }
                  },
                  child: Container(
                    height: 48.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryPink, AppColors.primaryPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPink.withValues(alpha: 0.3),
                          blurRadius: 12.r,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      "Exit",
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
