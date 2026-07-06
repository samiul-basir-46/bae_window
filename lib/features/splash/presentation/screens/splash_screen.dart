import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _textController;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _subtitleFadeAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_logoController);

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _titleSlideAnimation = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await _logoController.forward();

    _glowController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 150));
    await _textController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashBloc()..add(const CheckAuthStatusEvent()),
      child: BlocListener<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is UnauthenticatedState) {
            Navigator.pushReplacementNamed(context, Routes.loginScreen);
          } else if (state is AuthenticatedState) {
            Navigator.pushReplacementNamed(context, Routes.navigationScreen);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.c121212,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_logoController, _glowController]),
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow
                        Container(
                          width: 140.w,
                          height: 140.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFB03085).withValues(
                                    alpha: 0.22 * _glowAnimation.value *
                                        _logoFadeAnimation.value),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Logo box
                        Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Opacity(
                            opacity: _logoFadeAnimation.value,
                            child: child,
                          ),
                        ),
                      ],
                    );
                  },
                  child: Container(
                    width: 90.w,
                    height: 90.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(27.r),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF8FB8),
                          Color(0xFFD94E98),
                          Color(0xFFB03085),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB03085).withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 44.sp,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                // Title + Subtitle
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, _) {
                    return Column(
                      children: [
                        // "Bloom"
                        Opacity(
                          opacity: _titleFadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _titleSlideAnimation.value),
                            child: Text(
                              "Bloom",
                              style: TextFontStyle.textStyle38cFFFFFFSerif700,
                            ),
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // "just for two"
                        Opacity(
                          opacity: _subtitleFadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(
                                0, _titleSlideAnimation.value * 0.5),
                            child: Text(
                              "just for two",
                              style:
                                  TextFontStyle.textStyle16cCCCCCCSerifItalic,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}