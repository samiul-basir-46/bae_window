import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

import '../bloc/space_bloc.dart';
import '../bloc/space_event.dart';
import '../bloc/space_state.dart';
import '../widgets/live_status_indicator.dart';
import '../widgets/love_connection_card.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/activity_feed.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';

class SpaceScreen extends StatelessWidget {
  const SpaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SpaceBloc>(
      create: (context) => SpaceBloc()..add(const LoadSpaceEvent()),
      child: const SpaceScreenView(),
    );
  }
}

class SpaceScreenView extends StatelessWidget {
  const SpaceScreenView({super.key});

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
            child: BlocBuilder<SpaceBloc, SpaceState>(
              builder: (context, state) {
                if (state is SpaceLoading || state is SpaceInitial) {
                  return const Center(
                    child: BaeLoader(),
                  );
                } else if (state is SpaceLoaded) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(state),
                        UIHelper.verticalSpace(24.h),

                        // Connection Center Card (with animations)
                        LoveConnectionCard(
                          daysTogether: state.daysTogether,
                          mood: state.currentMood,
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
                          onSendLoveNote: (note) {
                            context.read<SpaceBloc>().add(SendLoveNoteEvent(note));
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
                            Icon(Icons.swap_vert_rounded, color: Colors.white24, size: 14.sp),
                          ],
                        ),
                        UIHelper.verticalSpace(12.h),
                        ActivityFeed(moments: state.recentMoments),
                        UIHelper.verticalSpace(100.h), // Safe space for nav bar
                      ],
                    ),
                  );
                } else if (state is SpaceError) {
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
        ],
      ),
    );
  }

  Widget _buildHeader(SpaceLoaded state) {
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
              "Good Morning, ${state.partnerName}",
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
          partnerName: state.partnerName,
        ),
      ],
    );
  }
}
