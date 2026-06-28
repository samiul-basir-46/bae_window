import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/story_state.dart';

class MemoryDetailScreen extends StatelessWidget {
  final MemoryItem memory;

  const MemoryDetailScreen({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlack,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 12) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            // Screen Background Glows
            Positioned(
              top: -50.h,
              right: -50.w,
              child: Container(
                width: 250.w,
                height: 250.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryPink.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full-width Image Area with Hero
                  Hero(
                    tag: 'memory_img_${memory.id}',
                    child: Container(
                      height: 420.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(memory.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                              AppColors.softBlack,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                  UIHelper.verticalSpace(16.h),
                  // Details
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              memory.dateString,
                              style: GoogleFonts.dmSans(
                                color: Colors.white38,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6.w,
                                    height: 6.h,
                                    decoration: BoxDecoration(
                                      color: memory.uploadedBy == "You"
                                          ? AppColors.primaryPurple
                                          : AppColors.primaryPink,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    memory.uploadedBy,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white70,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        UIHelper.verticalSpace(12.h),
                        if (memory.isMilestone) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.3),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: Colors.amber, size: 12.sp),
                                SizedBox(width: 4.w),
                                Text(
                                  "Milestone",
                                  style: GoogleFonts.dmSans(
                                    color: Colors.amber,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          UIHelper.verticalSpace(12.h),
                        ],
                        if (memory.isPrivate) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppColors.primaryPurple.withValues(alpha: 0.3),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_rounded, color: AppColors.primaryPurple, size: 12.sp),
                                SizedBox(width: 4.w),
                                Text(
                                  "Private Vault",
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.primaryPurple,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          UIHelper.verticalSpace(12.h),
                        ],
                        Text(
                          memory.title,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        UIHelper.verticalSpace(16.h),
                        Text(
                          memory.note,
                          style: GoogleFonts.dmSans(
                            color: Colors.white70,
                            fontSize: 14.sp,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  UIHelper.verticalSpace(100.h), // Safe space at bottom
                ],
              ),
            ),
            // Floating Close Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10.h,
              left: 20.w,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
