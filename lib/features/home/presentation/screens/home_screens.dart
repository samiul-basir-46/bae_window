import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/navigation_screen.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
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
    return BlocProvider<HomeBloc>(
      create: (context) => HomeBloc()..add(const LoadHomeDataEvent()),
      child: const HomeScreenView(),
    );
  }
}

class HomeScreenView extends StatelessWidget {
  const HomeScreenView({super.key});

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
              padding: EdgeInsets.only(left: 24.w, right: 24.w, top: 16.h, bottom: 120.h),
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoading) {
                    return SizedBox(
                      height: 500.h,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
                        ),
                      ),
                    );
                  } else if (state is HomeLoaded) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        HomeTopHeader(
                          userAvatarUrl: state.userAvatarUrl,
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
                        UIHelper.verticalSpace(20.h),
                        LivePeekCard(
                          imageUrl: state.livePeekImageUrl,
                          onTap: () {
                            const SwitchTabNotification(1).dispatch(context);
                          },
                        ),
                        UIHelper.verticalSpace(24.h),
                        const QuickActionDock(),
                        UIHelper.verticalSpace(24.h),
                        RelationshipPulseCard(data: state.relationshipPulse),
                        if (state.questionOfTheDay != null) ...[
                          UIHelper.verticalSpace(24.h),
                          QuestionOfTheDayCard(question: state.questionOfTheDay!),
                        ],
                        UIHelper.verticalSpace(24.h),
                        CheckInLogCard(logs: state.checkInLogs),
                        if (state.nextSpecialDay != null) ...[
                          UIHelper.verticalSpace(24.h),
                          NextSpecialDayCard(specialDay: state.nextSpecialDay!),
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
        ],
      ),
    );
  }
}
