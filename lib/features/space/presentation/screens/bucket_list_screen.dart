import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

class BucketListScreen extends StatefulWidget {
  const BucketListScreen({super.key});

  @override
  State<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen> {
  final List<Map<String, dynamic>> _goals = [
    {
      "title": "Visit Paris",
      "desc": "See the Eiffel Tower together and stroll down the Seine.",
      "progress": 0.3,
      "date": "Dec 2026",
    },
    {
      "title": "Learn Pottery",
      "desc": "Take a weekend workshop class together and make clay mugs.",
      "progress": 1.0,
      "date": "Completed",
    },
    {
      "title": "Skydiving Adventure",
      "desc": "Face our fears and jump from 15,000 feet!",
      "progress": 0.0,
      "date": "Aug 2027",
    },
  ];

  void _showNewGoalModal() {
    final titleController = TextEditingController();
    final dateController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navBgColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          "Add New Goal",
          style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: GoogleFonts.dmSans(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Goal Name",
                labelStyle: GoogleFonts.dmSans(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white12)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryPink)),
              ),
            ),
            UIHelper.verticalSpace(12.h),
            TextField(
              controller: dateController,
              style: GoogleFonts.dmSans(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Target Date (e.g. Dec 2026)",
                labelStyle: GoogleFonts.dmSans(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white12)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryPink)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel",
                style: GoogleFonts.dmSans(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final name = titleController.text.trim();
              final date = dateController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _goals.add({
                    "title": name,
                    "desc": "Shared dream waiting to be fulfilled.",
                    "progress": 0.0,
                    "date": date.isEmpty ? "TBD" : date,
                  });
                });
                Navigator.pop(dialogContext);
              }
            },
            child: Text(
              "Add Goal",
              style: GoogleFonts.dmSans(
                  color: AppColors.primaryPink, fontWeight: FontWeight.bold),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                UIHelper.verticalSpace(16.h),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                        left: 24.w, right: 24.w, top: 8.h, bottom: 120.h),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      return _buildGoalCard(goal);
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40.h,
            left: 24.w,
            right: 24.w,
            child: GestureDetector(
              onTap: _showNewGoalModal,
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

  Widget _buildHeader() {
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
                child: Icon(Icons.favorite_border_rounded,
                    color: AppColors.primaryPink, size: 20.sp),
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

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final double progress = goal["progress"];
    final bool isCompleted = progress >= 1.0;

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
                Text(
                  goal["title"]!,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                UIHelper.verticalSpace(4.h),
                Text(
                  goal["desc"]!,
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
                  "Target: ${goal["date"]!}",
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
          Stack(
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
        ],
      ),
    );
  }
}
