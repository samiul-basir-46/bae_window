import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/navigation_screen.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';
import '../../../../gen/assets.gen.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../bloc/home_action_bloc.dart';
import '../bloc/home_action_state.dart';
import '../widgets/home_top_header.dart';
import '../widgets/mood_card.dart';
import '../widgets/live_peek_card.dart';
import '../widgets/quick_action_dock.dart';
import '../widgets/relationship_pulse_card.dart';
import '../widgets/question_of_the_day_card.dart';
import '../widgets/check_in_log_card.dart';
import '../widgets/next_special_day_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc()..add(const LoadHomeDataEvent()),
        ),
        BlocProvider<HomeActionBloc>(
          create: (context) => HomeActionBloc(),
        ),
      ],
      child: const HomeScreenView(),
    );
  }
}

class HomeScreenView extends StatelessWidget {
  const HomeScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeActionBloc, HomeActionState>(
      listener: (context, state) {
        if (state is HomeActionLoading) {
          AppToast.show(
            context,
            title: "Please wait",
            message: state.message,
            type: ToastType.info,
            duration: const Duration(
                seconds: 5), // custom shorter duration for loading
          );
        } else if (state is HomeActionSuccess) {
          AppToast.show(
            context,
            title: "Success",
            message: state.message,
            type: ToastType.success,
          );
        } else if (state is HomeActionFailure) {
          AppToast.show(
            context,
            title: "Failed",
            message: state.message,
            type: ToastType.error,
          );
        }
      },
      child: Scaffold(
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
            Positioned(
              bottom: 50.h,
              right: -100.w,
              child: Container(
                width: 350.w,
                height: 350.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryPurple.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                    left: 24.w, right: 24.w, top: 16.h, bottom: 120.h),
                child: BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    if (state is HomeLoading) {
                      return SizedBox(
                        height: 500.h,
                        child: const BaeLoader(),
                      );
                    } else if (state is HomeLoaded) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          HomeTopHeader(
                            userAvatarUrl: state.userAvatarUrl,
                            isPaired: state.isPaired,
                            partnerAvatarUrl: state.partnerAvatarUrl,
                            partnerName: state.partnerName,
                            isPartnerOnline: state.isPartnerOnline,
                            daysTogether: state.daysTogether,
                          ),
                          UIHelper.verticalSpace(28.h),
                          MoodCard(
                            moodEmoji: state.userMoodEmoji,
                            moodText: state.userMoodText,
                          ),

                          // Partner's mood card (only when paired and partner has mood)
                          if (state.isPaired &&
                              state.partnerMoodEmoji != null) ...[
                            UIHelper.verticalSpace(12.h),
                            _buildPartnerMoodCard(
                              partnerName: state.partnerName ?? 'Partner',
                              emoji: state.partnerMoodEmoji!,
                              text: state.partnerMoodText ?? '',
                            ),
                          ],

                          // When unpaired — show invite partner card
                          if (!state.isPaired) ...[
                            UIHelper.verticalSpace(24.h),
                            _buildInvitePartnerCard(context, state.inviteCode),
                          ],

                          // Paired-only widgets
                          if (state.isPaired) ...[
                            UIHelper.verticalSpace(20.h),
                            LivePeekCard(
                              imageUrl: state.livePeekImageUrl,
                              drawingUrl: state.livePeekDrawingUrl,
                              voiceUrl: state.livePeekVoiceUrl,
                              partnerName: state.partnerName ?? 'Bae',
                              snapType: state.latestSnapType,
                              onTap: () {
                                const SwitchTabNotification(1)
                                    .dispatch(context);
                              },
                            ),
                            UIHelper.verticalSpace(24.h),
                            if (state.relationshipPulse.isNotEmpty) ...[
                              UIHelper.verticalSpace(24.h),
                              RelationshipPulseCard(
                                data: state.relationshipPulse,
                                partnerName: state.partnerName ?? 'Bae',
                              ),
                            ],
                            if (state.questionOfTheDay != null) ...[
                              UIHelper.verticalSpace(24.h),
                              QuestionOfTheDayCard(
                                question: state.questionOfTheDay!,
                                coupleId: state.coupleId ?? '',
                                partnerName: state.partnerName,
                              ),
                            ],
                            if (state.checkInLogs.isNotEmpty) ...[
                              UIHelper.verticalSpace(24.h),
                              CheckInLogCard(logs: state.checkInLogs),
                            ],
                            if (state.nextSpecialDay != null) ...[
                              UIHelper.verticalSpace(24.h),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    Routes.specialDayScreen,
                                    arguments: state.coupleId ?? '',
                                  );
                                },
                                child: NextSpecialDayCard(
                                    specialDay: state.nextSpecialDay!),
                              ),
                            ] else if (state.isPaired) ...[
                              UIHelper.verticalSpace(24.h),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    Routes.specialDayScreen,
                                    arguments: state.coupleId ?? '',
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24.r),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 15, sigmaY: 15),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(20.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.03),
                                        borderRadius:
                                            BorderRadius.circular(24.r),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.05),
                                          width: 1.w,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(
                                                left: 4.w, bottom: 8.h),
                                            child: Text(
                                              "SPECIAL DAYS",
                                              style: GoogleFonts.dmSans(
                                                color: Colors.white38,
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(10.w),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryPink
                                                      .withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  "📅",
                                                  style: TextStyle(
                                                      fontSize: 18.sp),
                                                ),
                                              ),
                                              SizedBox(width: 14.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "No upcoming special days",
                                                      style: GoogleFonts.dmSans(
                                                        color: Colors.white,
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    UIHelper.verticalSpace(2.h),
                                                    Text(
                                                      "Tap to add anniversaries, birthdays, and milestones! 🎉",
                                                      style: GoogleFonts.dmSans(
                                                        color: Colors.white38,
                                                        fontSize: 11.sp,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],

                          // Solo mode — Quick Action Dock still shown
                          if (!state.isPaired) ...[
                            UIHelper.verticalSpace(24.h),
                            const QuickActionDock(),
                          ],
                        ],
                      );
                    } else if (state is HomeError) {
                      return SizedBox(
                        height: 500.h,
                        child: Center(
                          child: Text(
                            state.message,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            Positioned(
              right: 24.w,
              bottom: 124.h,
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoaded && state.isPaired && state.coupleId != null) {
                    final parts = state.coupleId!.split('_');
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                    final partnerUid = parts.firstWhere((id) => id != currentUserId, orElse: () => '');
                    if (partnerUid.isNotEmpty) {
                      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('conversations')
                            .doc(state.coupleId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          int unreadCount = 0;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data();
                            final unreadCounts = data?['unreadCounts'] as Map<String, dynamic>?;
                            if (unreadCounts != null) {
                              unreadCount = (unreadCounts[currentUserId] as num?)?.toInt() ?? 0;
                            }
                          }

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    Routes.chatScreen,
                                    arguments: {
                                      'conversationId': state.coupleId,
                                      'partnerUid': partnerUid,
                                    },
                                  );
                                },
                                child: Container(
                                  width: 56.w,
                                  height: 56.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primaryPink, AppColors.primaryPurple],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryPink.withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Assets.icons.message.image(
                                      width: 24.w,
                                      height: 24.w,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  top: -4.h,
                                  right: -4.w,
                                  child: Container(
                                    padding: EdgeInsets.all(6.w),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE060A0),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 20.w,
                                      minHeight: 20.h,
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 99 ? '99+' : '$unreadCount',
                                        style: GoogleFonts.dmSans(
                                          color: Colors.white,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerMoodCard({
    required String partnerName,
    required String emoji,
    required String text,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: AppColors.primaryPink.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: AppColors.primaryPink.withValues(alpha: 0.1),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPink.withValues(alpha: 0.15),
                      AppColors.primaryPurple.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(emoji, style: TextStyle(fontSize: 22.sp)),
                ),
              ),
              UIHelper.horizontalSpace(14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$partnerName's Mood",
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    UIHelper.verticalSpace(2.h),
                    Text(
                      text,
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitePartnerCard(BuildContext context, String? inviteCode) {
    return GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, Routes.pairingScreen);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPink.withValues(alpha: 0.06),
                    AppColors.primaryPurple.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: AppColors.primaryPink.withValues(alpha: 0.12),
                  width: 1.w,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPink.withValues(alpha: 0.1),
                          AppColors.primaryPurple.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: AppColors.primaryPink,
                      size: 32.sp,
                    ),
                  ),
                  UIHelper.verticalSpace(16.h),
                  Text(
                    "Connect with your Partner",
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  UIHelper.verticalSpace(6.h),
                  Text(
                    "Share your invite code or enter your partner's code from Settings → Account & Pairing",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12.sp,
                      height: 1.5,
                    ),
                  ),
                  if (inviteCode != null && inviteCode.isNotEmpty) ...[
                    UIHelper.verticalSpace(20.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Text(
                        inviteCode,
                        style: GoogleFonts.dmSans(
                          color: AppColors.primaryPink,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    UIHelper.verticalSpace(12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSmallAction(
                          icon: Icons.copy_rounded,
                          label: "Copy",
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: inviteCode));
                            AppToast.show(
                              context,
                              title: "Copied",
                              message: "Code copied to clipboard!",
                              type: ToastType.success,
                            );
                          },
                        ),
                        SizedBox(width: 20.w),
                        _buildSmallAction(
                          icon: Icons.share_rounded,
                          label: "Share",
                          onTap: () {
                            SharePlus.instance.share(
                              ShareParams(
                                text:
                                    "Hey! Pair with me on Bae Window: $inviteCode ✦",
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildSmallAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16.sp),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white54,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
