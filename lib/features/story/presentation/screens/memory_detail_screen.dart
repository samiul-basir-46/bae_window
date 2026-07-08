import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/story_state.dart';

class MemoryDetailScreen extends StatefulWidget {
  final MemoryItem memory;

  const MemoryDetailScreen({super.key, required this.memory});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  late final List<String> _imagesList;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _imagesList = widget.memory.images.isNotEmpty
        ? widget.memory.images
        : [widget.memory.imageUrl].where((url) => url.isNotEmpty).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 420.h,
                        width: double.infinity,
                        child: _imagesList.isEmpty
                            ? Container(color: Colors.grey[900])
                            : PageView.builder(
                                controller: _pageController,
                                physics: const PageScrollPhysics(),
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentIndex = index;
                                  });
                                },
                                itemCount: _imagesList.length,
                                itemBuilder: (context, index) {
                                  return Image.network(
                                    _imagesList[index],
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child,
                                        loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                          color: AppColors.primaryPink,
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.broken_image_rounded,
                                          color: Colors.white24,
                                          size: 40,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                                AppColors.softBlack,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      if (_imagesList.length > 1)
                        Positioned(
                          bottom: 24.h,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _imagesList.length,
                              (index) {
                                final isSelected = _currentIndex == index;
                                return AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 4.w),
                                  width: isSelected ? 18.w : 6.w,
                                  height: 6.h,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryPink
                                        : Colors.white
                                            .withValues(alpha: 0.4),
                                    borderRadius:
                                        BorderRadius.circular(3.r),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryPink
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  UIHelper.verticalSpace(16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.memory.dateString,
                              style: GoogleFonts.dmSans(
                                color: Colors.white38,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.05),
                                borderRadius:
                                    BorderRadius.circular(10.r),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6.w,
                                    height: 6.h,
                                    decoration: BoxDecoration(
                                      color:
                                          widget.memory.uploadedBy == "You"
                                              ? AppColors.primaryPurple
                                              : AppColors.primaryPink,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    widget.memory.uploadedBy,
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
                        if (widget.memory.isMilestone) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color:
                                  Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.3),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 12.sp),
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
                        Text(
                          widget.memory.title,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        UIHelper.verticalSpace(16.h),
                        Text(
                          widget.memory.note,
                          style: GoogleFonts.dmSans(
                            color: Colors.white70,
                            fontSize: 14.sp,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  UIHelper.verticalSpace(100.h),
                ],
              ),
            ),
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