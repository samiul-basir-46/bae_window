import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

import '../bloc/space_screen_bloc.dart';
import '../bloc/space_screen_event.dart';
import '../bloc/space_screen_state.dart';
import '../models/bucket_list_model.dart';

class BucketListScreen extends StatelessWidget {
  const BucketListScreen({super.key});

  void _showNewGoalModal(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final dateController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          "Add New Goal",
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: GoogleFonts.dmSans(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Goal Name",
                  labelStyle: GoogleFonts.dmSans(color: Colors.white38),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryPink),
                  ),
                ),
              ),
              UIHelper.verticalSpace(12.h),
              TextField(
                controller: descController,
                style: GoogleFonts.dmSans(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Description",
                  labelStyle: GoogleFonts.dmSans(color: Colors.white38),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryPink),
                  ),
                ),
              ),
              UIHelper.verticalSpace(12.h),
              TextField(
                controller: dateController,
                style: GoogleFonts.dmSans(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Target Date (e.g. Dec 2026)",
                  labelStyle: GoogleFonts.dmSans(color: Colors.white38),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryPink),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel", style: GoogleFonts.dmSans(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final name = titleController.text.trim();
              final desc = descController.text.trim();
              final date = dateController.text.trim();
              if (name.isNotEmpty) {
                final newItem = BucketListItem(
                  id: '',
                  title: name,
                  description: desc.isEmpty ? 'Shared dream waiting to be fulfilled.' : desc,
                  date: date.isEmpty ? 'TBD' : date,
                  isCompleted: false,
                  progress: 0.0,
                  createdAt: DateTime.now(),
                );
                context.read<SpaceScreenBloc>().add(AddBucketItemEvent(newItem));
                Navigator.pop(dialogContext);
              }
            },
            child: Text(
              "Add Goal",
              style: GoogleFonts.dmSans(
                color: AppColors.primaryPink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditGoalModal(BuildContext context, BucketListItem item) {
    final titleController = TextEditingController(text: item.title);
    final descController = TextEditingController(text: item.description);
    final dateController = TextEditingController(text: item.date);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          "Edit Goal",
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: GoogleFonts.dmSans(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Goal Name",
                  labelStyle: GoogleFonts.dmSans(color: Colors.white38),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryPink),
                  ),
                ),
              ),
              UIHelper.verticalSpace(12.h),
              TextField(
                controller: descController,
                style: GoogleFonts.dmSans(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Description",
                  labelStyle: GoogleFonts.dmSans(color: Colors.white38),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryPink),
                  ),
                ),
              ),
              UIHelper.verticalSpace(12.h),
              TextField(
                controller: dateController,
                style: GoogleFonts.dmSans(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Target Date (e.g. Dec 2026)",
                  labelStyle: GoogleFonts.dmSans(color: Colors.white38),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryPink),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel", style: GoogleFonts.dmSans(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final name = titleController.text.trim();
              final desc = descController.text.trim();
              final date = dateController.text.trim();
              if (name.isNotEmpty) {
                final updatedItem = item.copyWith(
                  title: name,
                  description: desc,
                  date: date,
                );
                context.read<SpaceScreenBloc>().add(UpdateBucketItemEvent(updatedItem));
                Navigator.pop(dialogContext);
              }
            },
            child: Text(
              "Save",
              style: GoogleFonts.dmSans(
                color: AppColors.primaryPink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlack,
      body: Stack(
        children: [
          Positioned(
            top: -100.h,
            left: -50.w,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryPink.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: BlocBuilder<SpaceScreenBloc, SpaceScreenState>(
              builder: (context, state) {
                if (state is SpaceScreenLoading || state is SpaceScreenInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryPink),
                  );
                } else if (state is SpaceScreenLoaded) {
                  final list = state.bucketList;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      UIHelper.verticalSpace(16.h),
                      Expanded(
                        child: list.isEmpty
                            ? Center(
                                child: Text(
                                  "No goals in your shared bucket list yet! ✨",
                                  style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 13.sp),
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.only(
                                  left: 24.w,
                                  right: 24.w,
                                  top: 8.h,
                                  bottom: 120.h,
                                ),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final item = list[index];
                                  return _buildGoalCard(context, item);
                                },
                              ),
                      ),
                    ],
                  );
                } else if (state is SpaceScreenError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 14.sp),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          Positioned(
            bottom: 40.h,
            left: 24.w,
            right: 24.w,
            child: GestureDetector(
              onTap: () => _showNewGoalModal(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
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
                      color: AppColors.primaryPink.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  "+ Add New Goal",
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1.w,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                size: 16.sp,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: "hero-bucket-list-icon",
                child: Icon(Icons.favorite_border_rounded, color: AppColors.primaryPink, size: 20.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                "Bucket List",
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(width: 24.w),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, BucketListItem item) {
    final double progress = item.progress;
    final bool isCompleted = item.isCompleted;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64.w,
            height: 64.h,
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
            ),
            child: Icon(
              Icons.map_outlined,
              color: AppColors.primaryPink.withValues(alpha: 0.4),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_rounded, color: Colors.white24, size: 14.sp),
                      onPressed: () => _showEditGoalModal(context, item),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withValues(alpha: 0.6), size: 14.sp),
                      onPressed: () {
                        context.read<SpaceScreenBloc>().add(DeleteBucketItemEvent(item.id));
                      },
                    ),
                  ],
                ),
                UIHelper.verticalSpace(2.h),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 11.sp,
                    height: 1.4,
                  ),
                ),
                UIHelper.verticalSpace(6.h),
                Text(
                  "Target: ${item.date}",
                  style: GoogleFonts.dmSans(
                    color: isCompleted ? Colors.greenAccent : Colors.white24,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: () {
              final nextCompleted = !item.isCompleted;
              final nextProgress = nextCompleted ? 1.0 : 0.0;
              final updatedItem = item.copyWith(
                isCompleted: nextCompleted,
                progress: nextProgress,
              );
              context.read<SpaceScreenBloc>().add(UpdateBucketItemEvent(updatedItem));
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 44.w,
                  height: 44.h,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? Colors.greenAccent : AppColors.primaryPink,
                    ),
                  ),
                ),
                Icon(
                  isCompleted ? Icons.check_rounded : Icons.star_border_rounded,
                  color: isCompleted ? Colors.greenAccent : AppColors.primaryPink,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
