import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

import '../../bloc/space_screen_bloc.dart';
import '../../bloc/space_screen_event.dart';
import '../../bloc/space_screen_state.dart';
import '../widgets/live_status_indicator.dart';
import '../widgets/love_connection_card.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/activity_feed.dart';
import 'package:bea_window_app/common_widgets/custom_date_picker.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/common_widgets/floating_bubbles_background.dart';
import 'package:bea_window_app/helpers/all_routes.dart';

class SpaceScreen extends StatelessWidget {
  const SpaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SpaceScreenBloc>(
      create: (context) =>
          SpaceScreenBloc()..add(const LoadSpaceScreenDataEvent()),
      child: const SpaceScreenView(),
    );
  }
}

class SpaceScreenView extends StatelessWidget {
  const SpaceScreenView({super.key});

  Future<void> _selectAnniversary(
      BuildContext context, DateTime? currentDate) async {
    final now = DateTime.now();
    final pickedDate = await CustomDatePicker.show(
      context,
      initialDate: currentDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 50),
    );

    if (pickedDate != null && context.mounted) {
      context.read<SpaceScreenBloc>().add(UpdateAnniversaryEvent(pickedDate));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlack,
      body: Stack(
        children: [
          // Background Gradient highlights
          Positioned(
            top: -150.h,
            left: -100.w,
            child: Container(
              width: 400.w,
              height: 400.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E0B36).withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200.h,
            right: -150.w,
            child: Container(
              width: 450.w,
              height: 450.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF330921).withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Layout
          SafeArea(
            child: BlocBuilder<SpaceScreenBloc, SpaceScreenState>(
              builder: (context, state) {
                if (state is SpaceScreenLoading ||
                    state is SpaceScreenInitial) {
                  return const Center(
                    child: BaeLoader(),
                  );
                } else if (state is SpaceScreenLoaded) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(state),
                        UIHelper.verticalSpace(24.h),

                        // Connection Center Card (with anniversary count down)
                        LoveConnectionCard(
                          anniversaryDate: state.anniversaryDate,
                          onTapSelectAnniversary: () => _selectAnniversary(
                              context, state.anniversaryDate),
                        ),
                        UIHelper.verticalSpace(28.h),

                        // Quick Action Grid Section
                        Text(
                          "QUICK ACTIONS",
                          style: GoogleFonts.dmSans(
                            color: Colors.white38,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        UIHelper.verticalSpace(12.h),
                        QuickActionGrid(
                          taskProgress: state.taskProgress,
                          nextTaskTitle: state.nextTaskTitle,
                          partnerNickname: state.partnerNickname,
                          onSendLoveNote: (note) {
                            context
                                .read<SpaceScreenBloc>()
                                .add(SendSpaceLoveNoteEvent(note));
                            AppToast.show(
                              context,
                              title: "Love Note Sent 💌",
                              message:
                                  "Sent successfully to ${state.partnerNickname}!",
                              type: ToastType.success,
                            );
                          },
                        ),
                        UIHelper.verticalSpace(28.h),

                        // Activity Feed
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "RECENT MOMENTS",
                              style: GoogleFonts.dmSans(
                                color: Colors.white38,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Icon(Icons.swap_vert_rounded,
                                color: Colors.white24, size: 14.sp),
                          ],
                        ),
                        UIHelper.verticalSpace(12.h),
                        ActivityFeed(moments: state.recentMoments),
                        UIHelper.verticalSpace(100.h), // Safe space for nav bar
                      ],
                    ),
                  );
                } else if (state is SpaceScreenError) {
                  return _buildUnpairedView(context, state.message);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpairedView(BuildContext context, String message) {
    return FloatingBubblesBackground(
      bubbleColor: AppColors.primaryPink,
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryPink.withValues(alpha: 0.15),
                    width: 2.w,
                  ),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primaryPink,
                  size: 48.sp,
                ),
              ),
              UIHelper.verticalSpace(32.h),
              Text(
                "Your Space Awaits",
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              UIHelper.verticalSpace(12.h),
              Text(
                "Connect with your partner to share live photos, send love notes, list your bucket list, and count down your special days together.",
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: Colors.white54,
                  fontSize: 13.sp,
                  height: 1.5,
                ),
              ),
              UIHelper.verticalSpace(40.h),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, Routes.pairingScreen);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryPurple, AppColors.primaryPink],
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_rounded,
                          color: Colors.white, size: 18.sp),
                      SizedBox(width: 8.w),
                      Text(
                        "Pair with Partner",
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(SpaceScreenLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Our Space",
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            UIHelper.verticalSpace(2.h),
            Text(
              "Good Morning, ${state.partnerNickname}",
              style: GoogleFonts.dmSans(
                color: Colors.white38,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
        // Pulsing Live status indicator widget
        LiveStatusIndicator(
          isOnline: state.isPartnerOnline,
          partnerName: state.partnerNickname,
        ),
      ],
    );
  }
}
