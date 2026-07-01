import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/special_day_bloc.dart';
import '../bloc/special_day_event.dart';
import '../bloc/special_day_state.dart';
import '../models/special_day_model.dart';
import 'add_special_day_screen.dart';

class SpecialDayScreen extends StatelessWidget {
  final String coupleId;

  const SpecialDayScreen({super.key, required this.coupleId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SpecialDayBloc>(
      create: (context) => SpecialDayBloc()..add(WatchSpecialDaysEvent(coupleId)),
      child: Scaffold(
        backgroundColor: AppColors.softBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Our Special Days",
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
        ),
        body: BlocBuilder<SpecialDayBloc, SpecialDayState>(
          builder: (context, state) {
            if (state is SpecialDayLoading || state is SpecialDayInitial) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
            }

            if (state is SpecialDaysLoaded) {
            final days = state.days;

            if (days.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "No Special Days Added Yet",
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    UIHelper.verticalSpace(8.h),
                    Text(
                      "Add your first important date together!",
                      style: GoogleFonts.dmSans(
                        color: Colors.white30,
                        fontSize: 12.sp,
                      ),
                    ),
                    UIHelper.verticalSpace(24.h),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: Text(
                        "Add Special Day",
                        style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _openAddScreen(context),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final day = days[index];
                      return _buildDayCard(context, day);
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: Text(
                        "Add New Special Day",
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      onPressed: () => _openAddScreen(context),
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

  void _openAddScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (scrContext) => AddSpecialDayScreen(
          onSave: (title, desc, date) {
            context.read<SpecialDayBloc>().add(
                  AddSpecialDayEvent(
                    coupleId: coupleId,
                    day: SpecialDayModel(
                      id: '',
                      title: title,
                      description: desc,
                      date: date,
                      createdAt: DateTime.now(),
                    ),
                  ),
                );
          },
        ),
      ),
    );
  }

  void _openEditScreen(BuildContext context, SpecialDayModel day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (scrContext) => AddSpecialDayScreen(
          existingDay: day,
          onSave: (title, desc, date) {
            context.read<SpecialDayBloc>().add(
                  UpdateSpecialDayEvent(
                    coupleId: coupleId,
                    day: day.copyWith(
                      title: title,
                      description: desc,
                      date: date,
                    ),
                  ),
                );
          },
        ),
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, SpecialDayModel day) {
    final formattedDate = DateFormat('MMMM d, yyyy').format(day.date);
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  day.title,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_rounded, color: Colors.white54, size: 18.sp),
                    onPressed: () => _openEditScreen(context, day),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withValues(alpha: 0.8), size: 18.sp),
                    onPressed: () {
                      _showDeleteConfirmation(context, day.id);
                    },
                  ),
                ],
              )
            ],
          ),
          UIHelper.verticalSpace(4.h),
          Text(
            formattedDate,
            style: GoogleFonts.dmSans(
              color: AppColors.primaryPink,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (day.description.isNotEmpty) ...[
            UIHelper.verticalSpace(10.h),
            Text(
              day.description,
              style: GoogleFonts.dmSans(
                color: Colors.white54,
                fontSize: 12.sp,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String dayId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.navBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text(
            "Delete Special Day",
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to delete this special day?",
            style: GoogleFonts.dmSans(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: GoogleFonts.dmSans(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () {
                context.read<SpecialDayBloc>().add(
                      DeleteSpecialDayEvent(coupleId: coupleId, dayId: dayId),
                    );
                Navigator.pop(dialogContext);
              },
              child: Text("Delete", style: GoogleFonts.dmSans(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}
