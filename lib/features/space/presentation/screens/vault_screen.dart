import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  String _selectedFilter = "All";

  final List<Map<String, String>> _mediaItems = [
    {"type": "photo", "url": "assets/images/placeholder_1.png", "date": "TODAY"},
    {"type": "photo", "url": "assets/images/placeholder_2.png", "date": "TODAY"},
    {"type": "video", "url": "assets/images/placeholder_3.png", "date": "TODAY"},
    {"type": "photo", "url": "assets/images/placeholder_4.png", "date": "YESTERDAY"},
    {"type": "video", "url": "assets/images/placeholder_5.png", "date": "YESTERDAY"},
    {"type": "photo", "url": "assets/images/placeholder_6.png", "date": "1 WEEK AGO"},
  ];

  void _uploadNewMedia() {
    AppToast.show(
      context,
      title: "Upload",
      message: "Select photos/videos from gallery...",
      type: ToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMedia = _mediaItems.where((item) {
      if (_selectedFilter == "All") return true;
      if (_selectedFilter == "Photos") return item["type"] == "photo";
      if (_selectedFilter == "Videos") return item["type"] == "video";
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.softBlack,
      body: Stack(
        children: [
          // Background Glow (Purple)
          Positioned(
            top: -100.h,
            right: -50.w,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryPurple.withValues(alpha: 0.15),
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
                _buildFilterBar(),
                UIHelper.verticalSpace(20.h),
                Expanded(
                  child: filteredMedia.isEmpty
                      ? _buildEmptyState()
                      : _buildGridSection(filteredMedia),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _uploadNewMedia,
                backgroundColor: AppColors.primaryPurple,
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                child: Icon(Icons.add_rounded, color: Colors.white, size: 26.sp),
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
                tag: "hero-vault-icon",
                child: Icon(Icons.lock_outline_rounded, color: AppColors.primaryPurple, size: 20.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                "Vault",
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

  Widget _buildFilterBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: ["All", "Photos", "Videos"].map((filter) {
            final isSelected = _selectedFilter == filter;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryPurple.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.dmSans(
                      color: Colors.white38,
                      fontSize: 12.sp,
                      fontWeight: DateUtils.isSameDay(DateTime.now(), DateTime.now()) && isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGridSection(List<Map<String, String>> media) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(left: 24.w, right: 24.w, top: 8.h, bottom: 120.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final item = media[index];
        final isVideo = item["type"] == "video";

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1.w,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.03),
                      AppColors.primaryPurple.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  isVideo ? Icons.play_circle_outline_rounded : Icons.photo_outlined,
                  color: Colors.white24,
                  size: 32.sp,
                ),
              ),
              if (isVideo)
                Positioned(
                  top: 6.h,
                  right: 6.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 10.sp),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, color: Colors.white24, size: 48.sp),
          UIHelper.verticalSpace(16.h),
          Text(
            "No Media Found",
            style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          UIHelper.verticalSpace(4.h),
          Text(
            "Tap '+' below to add your first photo or video!",
            style: GoogleFonts.dmSans(color: Colors.white24, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}
