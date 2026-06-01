import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../widgets/onboarding_artworks.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  final List<OnboardingSlideModel> _slides = [
    OnboardingSlideModel(
      title: "Your Partner, Just a Glance Away",
      subtitle: "Your partner's live memory is now right on your phone screen. Stay close without opening the app.",
      artwork: const Slide1Artwork(),
    ),
    OnboardingSlideModel(
      title: "Sync Moods & Moments",
      subtitle: "Share your moods, relationship milestones, and little moments of love.",
      artwork: const Slide2Artwork(),
    ),
    OnboardingSlideModel(
      title: "Our Private Space",
      subtitle: "A completely ad-free and secure world, built just for the two of you.",
      artwork: const Slide3Artwork(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingBloc(),
      child: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingFinished) {
            Navigator.pushReplacementNamed(context, Routes.loginScreen);
          }
        },
        builder: (context, state) {
          final int currentIndex = state.pageIndex;

          return Scaffold(
            backgroundColor: AppColors.c111113,
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: 16.h,
                    right: 24.w,
                    child: AnimatedOpacity(
                      opacity: currentIndex < 2 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: currentIndex >= 2,
                        child: TextButton(
                          onPressed: () {
                            _pageController.animateToPage(
                              2,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOutCubic,
                            );
                          },
                          child: Text(
                            "Skip",
                            style: TextStyle(
                              color: AppColors.c8E8E9F,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 60.h, bottom: 100.h),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (index) {
                        context.read<OnboardingBloc>().add(PageChangedEvent(index));
                      },
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 5,
                                child: slide.artwork,
                              ),
                              SizedBox(height: 24.h),
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  color: Colors.white,
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Text(
                                slide.subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF8E8E9F),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                  height: 1.5.h,
                                ),
                              ),
                              const Spacer(flex: 1),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 32.h,
                    left: 32.w,
                    right: 32.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(
                            _slides.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: EdgeInsets.only(right: 8.w),
                              height: 8.h,
                              width: currentIndex == index ? 24.w : 8.w,
                              decoration: BoxDecoration(
                                color: currentIndex == index
                                    ? AppColors.cFFB7CE
                                    : AppColors.c2C2C35,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (currentIndex < 2) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                              );
                            } else {
                              context.read<OnboardingBloc>().add(const FinishOnboardingEvent());
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                            height: 56.h,
                            width: currentIndex == 2 ? 180.w : 56.w,
                            decoration: BoxDecoration(
                              color: AppColors.cFFB7CE,
                              borderRadius: BorderRadius.circular(currentIndex == 2 ? 16.r : 28.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cFFB7CE.withValues(alpha: 0.35),
                                  blurRadius: currentIndex == 2 ? 16.r : 10.r,
                                  spreadRadius: 1.w,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: AnimatedCrossFade(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.center,
                              crossFadeState: currentIndex == 2
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.cFF3A1222,
                                size: 24.sp,
                              ),
                              secondChild: Text(
                                "Create Our Window",
                                style: TextStyle(
                                  color: AppColors.cFF3A1222,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class OnboardingSlideModel {
  final String title;
  final String subtitle;
  final Widget artwork;

  OnboardingSlideModel({
    required this.title,
    required this.subtitle,
    required this.artwork,
  });
}
