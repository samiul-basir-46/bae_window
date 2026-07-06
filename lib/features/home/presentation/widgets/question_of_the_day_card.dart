import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';

class QuestionOfTheDayCard extends StatelessWidget {
  final TriviaQuestion question;
  final String? partnerName;
  final String coupleId;

  const QuestionOfTheDayCard({
    super.key,
    required this.question,
    required this.coupleId,
    this.partnerName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            "QUESTION OF THE DAY",
            style: GoogleFonts.dmSans(
              color: Colors.white38,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1.w,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white70,
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    "DAILY TRIVIA",
                    style: GoogleFonts.dmSans(
                      color: AppColors.primaryPink,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              UIHelper.verticalSpace(16.h),
              Text(
                question.questionText,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              _buildAnswersView(context),
              UIHelper.verticalSpace(20.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.15),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      side: BorderSide(
                        color: AppColors.primaryPurple.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                    ),
                  ),
                   onPressed: () {
                    final hasUserAnswered = question.isAnswered;
                    final hasPartnerAnswered = question.hasPartnerAnswered;
                    final triggerInvite = !hasUserAnswered && !hasPartnerAnswered;

                    if (triggerInvite) {
                      context.read<HomeBloc>().add(
                        AnswerQuestionTogetherEvent(question.questionText),
                      );
                      final displayPartnerName = partnerName != null && partnerName!.isNotEmpty ? partnerName : 'partner';
                      AppToast.show(
                        context,
                        title: "Invitation Sent",
                        message: "Trivia invitation sent to $displayPartnerName!",
                        type: ToastType.success,
                      );
                    }

                    Navigator.pushNamed(
                      context,
                      Routes.triviaScreen,
                      arguments: {
                        'coupleId': coupleId,
                        'questionText': question.questionText,
                      },
                    );
                  },
                  child: Text(
                    _getButtonText(),
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswersView(BuildContext context) {
    final hasUserAnswered = question.isAnswered;
    final hasPartnerAnswered = question.hasPartnerAnswered;
    final displayName = partnerName != null && partnerName!.isNotEmpty ? partnerName! : 'Partner';

    if (hasUserAnswered && hasPartnerAnswered) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UIHelper.verticalSpace(14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Answer:",
                  style: GoogleFonts.dmSans(color: Colors.tealAccent, fontSize: 11.sp, fontWeight: FontWeight.bold),
                ),
                UIHelper.verticalSpace(4.h),
                Text(
                  question.userAnswer ?? '',
                  style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12.sp),
                ),
                UIHelper.verticalSpace(10.h),
                Text(
                  "$displayName's Answer:",
                  style: GoogleFonts.dmSans(color: AppColors.primaryPink, fontSize: 11.sp, fontWeight: FontWeight.bold),
                ),
                UIHelper.verticalSpace(4.h),
                Text(
                  question.partnerAnswer ?? '',
                  style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (hasUserAnswered) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UIHelper.verticalSpace(14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Answer:",
                  style: GoogleFonts.dmSans(color: Colors.tealAccent, fontSize: 11.sp, fontWeight: FontWeight.bold),
                ),
                UIHelper.verticalSpace(4.h),
                Text(
                  question.userAnswer ?? '',
                  style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12.sp),
                ),
                UIHelper.verticalSpace(10.h),
                Row(
                  children: [
                    const BaeLoader(
                      isFullScreen: false,
                      size: 12.0,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "Waiting for $displayName...",
                      style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11.sp, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else if (hasPartnerAnswered) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UIHelper.verticalSpace(14.h),
          Row(
            children: [
              Icon(Icons.lock_rounded, color: AppColors.primaryPink, size: 14.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  "$displayName answered! Reveal by answering above 🔒",
                  style: GoogleFonts.dmSans(color: AppColors.primaryPink, fontSize: 11.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  String _getButtonText() {
    final hasUserAnswered = question.isAnswered;
    final hasPartnerAnswered = question.hasPartnerAnswered;

    if (hasUserAnswered && hasPartnerAnswered) {
      return "View Conversation";
    } else if (hasUserAnswered) {
      return "View status";
    } else if (hasPartnerAnswered) {
      return "Write your answer";
    }
    return "Answer together →";
  }
}
