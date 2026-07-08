import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  late final ScrollController _thumbScrollController;
  int _currentIndex = 0;
  late final List<String> _imagesList;

  @override
  void initState() {
    super.initState();
    _thumbScrollController = ScrollController();
    _imagesList = widget.memory.images.isNotEmpty
        ? widget.memory.images
        : [widget.memory.imageUrl].where((url) => url.isNotEmpty).toList();
  }

  @override
  void dispose() {
    _thumbScrollController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _scrollThumbIntoView(index);
  }

  void _onThumbnailTap(int index) {
    setState(() => _currentIndex = index);
    _carouselController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _scrollThumbIntoView(index);
  }

  void _scrollThumbIntoView(int index) {
    if (!_thumbScrollController.hasClients) return;
    final thumbWidth = 60.w + 8.w;
    final targetOffset = index * thumbWidth;
    final maxOffset = _thumbScrollController.position.maxScrollExtent;
    _thumbScrollController.animateTo(
      targetOffset.clamp(0.0, maxOffset),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlack,
      body: Stack(
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
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildMainImageArea()),
              if (_imagesList.length > 1) ...[
                SliverToBoxAdapter(child: UIHelper.verticalSpace(12.h)),
                SliverToBoxAdapter(child: _buildThumbnailRow()),
              ],
              SliverToBoxAdapter(child: UIHelper.verticalSpace(16.h)),
              SliverToBoxAdapter(child: _buildDetails()),
              SliverToBoxAdapter(child: UIHelper.verticalSpace(100.h)),
            ],
          ),
          _buildBackButton(context),
        ],
      ),
    );
  }

  Widget _buildMainImageArea() {
    return Stack(
      children: [
        SizedBox(
          height: 380.h,
          width: double.infinity,
          child: _imagesList.isEmpty
              ? Container(color: Colors.grey[900])
              : CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: _imagesList.length,
                  options: CarouselOptions(
                    height: 380.h,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: false,
                    scrollPhysics: const PageScrollPhysics(),
                    onPageChanged: (index, reason) => _onPageChanged(index),
                  ),
                  itemBuilder: (context, index, realIndex) {
                    final imageUrl = _imagesList[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox.shrink();
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                        ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        Center(
                          child: index == 0
                              ? Hero(
                                  tag: 'memory_image_${widget.memory.id}',
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
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
                                        (context, error, stackTrace) =>
                                            const Center(
                                      child: Icon(
                                        Icons.broken_image_rounded,
                                        color: Colors.white24,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                )
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
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
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.white24,
                                      size: 40,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        Positioned.fill(
          child: IgnorePointer(
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
        ),
        if (_imagesList.length > 1)
          Positioned(
            bottom: 16.h,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_imagesList.length, (index) {
                  final isSelected = _currentIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    width: isSelected ? 16.w : 5.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryPink
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3.r),
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
                }),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnailRow() {
    return SizedBox(
      height: 64.h,
      child: ListView.builder(
        controller: _thumbScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _imagesList.length,
        itemBuilder: (context, index) {
          final isSelected = _currentIndex == index;
          final remainingCount = _imagesList.length - 4;
          final showCountOverlay = _imagesList.length > 4 && index == 3;

          return GestureDetector(
            onTap: () => _onThumbnailTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: 8.w),
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primaryPink : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _imagesList[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: Center(
                            child: SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.primaryPink,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white24,
                            size: 20.sp,
                          ),
                        );
                      },
                    ),
                    if (!isSelected)
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    if (showCountOverlay)
                      Container(
                        color: Colors.black.withValues(alpha: 0.6),
                        child: Center(
                          child: Text(
                            '+$remainingCount',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetails() {
    return Padding(
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
                        color: widget.memory.uploadedBy == "You"
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
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
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
    );
  }
}
