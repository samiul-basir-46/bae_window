import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/trivia_bloc.dart';
import '../bloc/trivia_event.dart';
import '../bloc/trivia_state.dart';
import '../models/trivia_model.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';

class TriviaScreen extends StatefulWidget {
  final String coupleId;
  final String questionText;

  const TriviaScreen({
    super.key,
    required this.coupleId,
    required this.questionText,
  });

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  final _answerController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final String _dateYmd = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final String? _currentUserUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserUid == null) {
      return const Scaffold(
        body: Center(child: Text("User not authenticated.")),
      );
    }

    return BlocProvider<TriviaBloc>(
      create: (context) => TriviaBloc()
        ..add(WatchTriviaEvent(coupleId: widget.coupleId, dateYmd: _dateYmd)),
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
            "Answer Together",
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
        ),
        body: BlocListener<TriviaBloc, TriviaState>(
          listener: (context, state) {
            if (state is TriviaSuccess) {
              AppToast.show(
                context,
                title: "Success",
                message: state.message,
                type: ToastType.success,
              );
            } else if (state is TriviaFailure) {
              AppToast.show(
                context,
                title: "Failed",
                message: state.error,
                type: ToastType.error,
              );
            }
          },
          child: Stack(
            children: [
              // Background glow highlights
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
                        AppColors.primaryPink.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100.h,
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
                child: BlocBuilder<TriviaBloc, TriviaState>(
                  builder: (context, state) {
                    if (state is TriviaLoading || state is TriviaInitial) {
                      return const Center(
                        child: BaeLoader(),
                      );
                    }

                    if (state is TriviaLoaded || state is TriviaSubmitting || state is TriviaSuccess || state is TriviaFailure) {
                      TriviaModel? trivia;
                      if (state is TriviaLoaded) {
                        trivia = state.trivia;
                      }

                      final userAnswer = trivia?.answers[_currentUserUid];
                      final hasUserAnswered = userAnswer != null && userAnswer.isNotEmpty;

                      // Find partner answer
                      String? partnerAnswer;
                      if (trivia != null) {
                        for (final entry in trivia.answers.entries) {
                          if (entry.key != _currentUserUid) {
                            partnerAnswer = entry.value;
                            break;
                          }
                        }
                      }
                      final hasPartnerAnswered = partnerAnswer != null && partnerAnswer.isNotEmpty;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildQuestionCard(),
                            UIHelper.verticalSpace(28.h),
                            if (!hasUserAnswered) ...[
                              _buildAnswerInputForm(context),
                            ] else ...[
                              _buildYourAnswerCard(userAnswer),
                            ],
                            UIHelper.verticalSpace(24.h),
                            _buildPartnerAnswerCard(hasUserAnswered, hasPartnerAnswered, partnerAnswer),
                            UIHelper.verticalSpace(40.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "Back to Home",
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.format_quote_rounded, color: AppColors.primaryPink, size: 28.sp),
                  SizedBox(width: 8.w),
                  Text(
                    "TODAY'S QUESTION",
                    style: GoogleFonts.dmSans(
                      color: AppColors.primaryPink,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              UIHelper.verticalSpace(16.h),
              Text(
                widget.questionText,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerInputForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "YOUR ANSWER",
            style: GoogleFonts.dmSans(
              color: Colors.white38,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          UIHelper.verticalSpace(12.h),
          TextFormField(
            controller: _answerController,
            maxLines: 4,
            cursorColor: AppColors.primaryPink,
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: "Type your answer here...",
              hintStyle: GoogleFonts.dmSans(color: Colors.white24, fontSize: 13.sp),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.02),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.r),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.r),
                borderSide: const BorderSide(color: AppColors.primaryPink),
              ),
              contentPadding: EdgeInsets.all(16.w),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Answer cannot be empty";
              }
              return null;
            },
          ),
          UIHelper.verticalSpace(16.h),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: const LinearGradient(
                  colors: [AppColors.primaryPink, AppColors.primaryPurple],
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  context.read<TriviaBloc>().add(
                        SubmitTriviaAnswerEvent(
                          coupleId: widget.coupleId,
                          dateYmd: _dateYmd,
                          questionText: widget.questionText,
                          uid: _currentUserUid!,
                          answer: _answerController.text.trim(),
                        ),
                      );
                },
                child: Text(
                  "Submit Answer",
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourAnswerCard(String answer) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.tealAccent, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                "YOUR ANSWER SUBMITTED",
                style: GoogleFonts.dmSans(
                  color: Colors.tealAccent,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          UIHelper.verticalSpace(14.h),
          Text(
            answer,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerAnswerCard(bool hasUserAnswered, bool hasPartnerAnswered, String? partnerAnswer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PARTNER'S ANSWER",
          style: GoogleFonts.dmSans(
            color: Colors.white38,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        UIHelper.verticalSpace(12.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: (!hasUserAnswered && hasPartnerAnswered) ? 12.0 : 0.0,
              sigmaY: (!hasUserAnswered && hasPartnerAnswered) ? 12.0 : 0.0,
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: _buildPartnerStatusBody(hasUserAnswered, hasPartnerAnswered, partnerAnswer),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerStatusBody(bool hasUserAnswered, bool hasPartnerAnswered, String? partnerAnswer) {
    if (!hasPartnerAnswered) {
      return Row(
        children: [
          const BaeLoader(
            isFullScreen: false,
            size: 16,
          ),
          SizedBox(width: 12.w),
          Text(
            "Bae is still thinking... 💭",
            style: GoogleFonts.dmSans(
              color: Colors.white38,
              fontSize: 13.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    if (!hasUserAnswered) {
      return Row(
        children: [
          Icon(Icons.lock_rounded, color: AppColors.primaryPink, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              "Bae answered! Reveal by answering above 🔒",
              style: GoogleFonts.dmSans(
                color: AppColors.primaryPink,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite_rounded, color: AppColors.primaryPink, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              "BAE'S ANSWER REVEALED",
              style: GoogleFonts.dmSans(
                color: AppColors.primaryPink,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        UIHelper.verticalSpace(14.h),
        Text(
          partnerAnswer ?? '',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 14.sp,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
