import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/story_state.dart';
import '../screens/memory_detail_screen.dart';

class FullWidthMemoryCard extends StatelessWidget {
  final MemoryItem memory;
  final VoidCallback onLongPress;

  const FullWidthMemoryCard({
    super.key,
    required this.memory,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MemoryDetailScreen(memory: memory)),
        );
      },
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: memory.isMilestone ? Colors.amber.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05),
            width: memory.isMilestone ? 1.5.w : 1.w,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withValues(alpha: 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Hero(
                        tag: 'memory_img_${memory.id}',
                        child: Container(
                          height: 240.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(memory.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      if (memory.isMilestone)
                        Positioned(
                          top: 14.h,
                          right: 14.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star_rounded, color: Colors.amber, size: 10.sp),
                                SizedBox(width: 4.w),
                                Text(
                                  "Milestone",
                                  style: GoogleFonts.dmSans(
                                    color: Colors.amber,
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              memory.dateString,
                              style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 10.sp),
                            ),
                            Row(
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
                                SizedBox(width: 4.w),
                                Text(
                                  memory.uploadedBy,
                                  style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 9.sp),
                                ),
                              ],
                            ),
                          ],
                        ),
                        UIHelper.verticalSpace(6.h),
                        Text(
                          memory.note,
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GridMemoryCard extends StatelessWidget {
  final MemoryItem memory;
  final VoidCallback onLongPress;

  const GridMemoryCard({
    super.key,
    required this.memory,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MemoryDetailScreen(memory: memory)),
        );
      },
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1.w,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withValues(alpha: 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'memory_img_${memory.id}',
                    child: Container(
                      height: 120.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(memory.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memory.dateString,
                          style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 9.sp),
                        ),
                        UIHelper.verticalSpace(4.h),
                        Text(
                          memory.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrivateVaultEntryCard extends StatelessWidget {
  final bool isUnlocked;
  final VoidCallback onTap;

  const PrivateVaultEntryCard({
    super.key,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 16.h),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.primaryPurple.withValues(alpha: 0.2),
                  width: 1.w,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                      color: AppColors.primaryPurple,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Private Vault",
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        UIHelper.verticalSpace(2.h),
                        Text(
                          isUnlocked ? "Tap to view private memories" : "Locked — Tap to unlock",
                          style: GoogleFonts.dmSans(
                            color: Colors.white38,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white38,
                    size: 14.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
