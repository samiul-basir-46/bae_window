import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/common_widgets/custom_date_picker.dart';
import 'package:intl/intl.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';

import '../../bloc/space_screen_bloc.dart';
import '../../bloc/space_screen_event.dart';
import '../../bloc/space_screen_state.dart';
import '../../models/bucket_list_model.dart';

class BucketListScreen extends StatelessWidget {
  const BucketListScreen({super.key});

  void _showNewGoalModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => _BucketGoalDialog(
        onSave: (title, desc, date) {
          final newItem = BucketListItem(
            id: '',
            title: title,
            description:
                desc.isEmpty ? 'Shared dream waiting to be fulfilled.' : desc,
            date: date.isEmpty ? 'TBD' : date,
            isCompleted: false,
            progress: 0.0,
            createdAt: DateTime.now(),
          );
          context.read<SpaceScreenBloc>().add(AddBucketItemEvent(newItem));
        },
      ),
    );
  }

  void _showEditGoalModal(BuildContext context, BucketListItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => _BucketGoalDialog(
        item: item,
        onSave: (title, desc, date) {
          final updatedItem = item.copyWith(
            title: title,
            description: desc,
            date: date,
          );
          context
              .read<SpaceScreenBloc>()
              .add(UpdateBucketItemEvent(updatedItem));
        },
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
                if (state is SpaceScreenLoading ||
                    state is SpaceScreenInitial) {
                  return const Center(
                    child: BaeLoader(),
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
                                  style: GoogleFonts.dmSans(
                                      color: Colors.white38, fontSize: 13.sp),
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
                      style: GoogleFonts.dmSans(
                          color: Colors.redAccent, fontSize: 14.sp),
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
                      icon: Icon(Icons.edit_rounded,
                          color: Colors.white24, size: 14.sp),
                      onPressed: () => _showEditGoalModal(context, item),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent.withValues(alpha: 0.6),
                          size: 14.sp),
                      onPressed: () {
                        context
                            .read<SpaceScreenBloc>()
                            .add(DeleteBucketItemEvent(item.id));
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
              context
                  .read<SpaceScreenBloc>()
                  .add(UpdateBucketItemEvent(updatedItem));
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
                  color:
                      isCompleted ? Colors.greenAccent : AppColors.primaryPink,
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

class _BucketGoalDialog extends StatefulWidget {
  final BucketListItem? item;
  final Function(String title, String desc, String date) onSave;

  const _BucketGoalDialog({
    this.item,
    required this.onSave,
  });

  @override
  State<_BucketGoalDialog> createState() => _BucketGoalDialogState();
}

class _BucketGoalDialogState extends State<_BucketGoalDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _descController =
        TextEditingController(text: widget.item?.description ?? '');
    if (widget.item?.date != null && widget.item!.date != 'TBD') {
      try {
        _selectedDate = DateFormat('MMM d, yyyy').parse(widget.item!.date);
      } catch (_) {
        _selectedDate = DateTime.tryParse(widget.item!.date);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await CustomDatePicker.show(
      context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final dateText = _selectedDate != null
        ? DateFormat('MMM d, yyyy').format(_selectedDate!)
        : 'Select Target Date';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(24.r),
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
              blurRadius: 20.r,
              spreadRadius: 2.r,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? "Edit Goal" : "Add New Goal",
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              UIHelper.verticalSpace(16.h),

              // Goal Name Input
              Text(
                "GOAL NAME",
                style: GoogleFonts.dmSans(
                    color: Colors.white38,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold),
              ),
              UIHelper.verticalSpace(6.h),
              TextField(
                controller: _titleController,
                cursorColor: Colors.white,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: "Enter goal name...",
                  hintStyle: GoogleFonts.dmSans(
                      color: const Color(0xFF555568), fontSize: 14.sp),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: Color(0xFFD94E98)),
                  ),
                ),
              ),
              UIHelper.verticalSpace(16.h),

              // Description Input
              Text(
                "DESCRIPTION",
                style: GoogleFonts.dmSans(
                    color: Colors.white38,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold),
              ),
              UIHelper.verticalSpace(6.h),
              TextField(
                controller: _descController,
                cursorColor: Colors.white,
                maxLines: 3,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: "Enter description...",
                  hintStyle: GoogleFonts.dmSans(
                      color: const Color(0xFF555568), fontSize: 14.sp),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: Color(0xFFD94E98)),
                  ),
                ),
              ),
              UIHelper.verticalSpace(16.h),

              // Target Date Selector Button
              Text(
                "TARGET DATE",
                style: GoogleFonts.dmSans(
                    color: Colors.white38,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold),
              ),
              UIHelper.verticalSpace(6.h),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateText,
                        style: GoogleFonts.dmSans(
                          color: _selectedDate != null
                              ? Colors.white
                              : const Color(0xFF555568),
                          fontSize: 14.sp,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.primaryPink,
                        size: 18.sp,
                      ),
                    ],
                  ),
                ),
              ),
              UIHelper.verticalSpace(24.h),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.dmSans(
                        color: Colors.white54,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: () {
                      final name = _titleController.text.trim();
                      final desc = _descController.text.trim();
                      if (name.isNotEmpty) {
                        widget.onSave(
                            name,
                            desc,
                            _selectedDate != null
                                ? DateFormat('MMM d, yyyy')
                                    .format(_selectedDate!)
                                : '');
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      isEdit ? "Save Changes" : "Add Goal",
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
