import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/features/auth/presentation/screens/login_screen.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // 1. Entrance Controller (runs once for a premium staggered intro)
  late AnimationController _entranceController;
  late Animation<double> _heartFadeAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<double> _footerFadeAnimation;

  // 2. Pulse Controller (runs infinitely for the organic lub-dub heartbeat)
  late AnimationController _pulseController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _glowIntensityAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _heartFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Brand Title fades + slides in
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
      ),
    );
    _titleSlideAnimation = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Subtitle ("just a glance away") fades in
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 0.75).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );

    // Footer ("MADE FOR TWO") fades in last
    _footerFadeAnimation = Tween<double>(begin: 0.0, end: 0.45).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start entrance animations
    _entranceController.forward();

    // ==========================================
    // ORGANIC DOUBLE-PUMP HEARTBEAT ANIMATIONS
    // ==========================================
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Mimics a real heartbeat (lub-dub... rest... lub-dub...)
    _heartScaleAnimation = TweenSequence<double>([
      // First quick beat (lub)
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.03)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 10,
      ),
      // Second stronger beat (dub)
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.03, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 24,
      ),
      // Muted rest state (rest)
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40,
      ),
    ]).animate(_pulseController);

    // Sync glow intensity (blur/spread) in tandem with the double pump
    _glowIntensityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.45, end: 0.75)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.75, end: 0.55)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.55, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.45)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 24,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.45),
        weight: 40,
      ),
    ]).animate(_pulseController);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashBloc()..add(const CheckAuthStatusEvent()),
      child: BlocListener<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is UnauthenticatedState) {
            // Push-replace to onboarding login flow smoothly
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 1000),
                reverseTransitionDuration: const Duration(milliseconds: 800),
                pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                    child: child,
                  );
                },
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF121212), // Deep premium aesthetic charcoal-black
          body: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient faint background glow representing cozy space link
              Positioned(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 280.w,
                        height: 280.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFFB3C6).withValues(alpha: 0.08 * _glowIntensityAnimation.value),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Center Column: Heart & Brand Typography
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ==========================================
                    // GLOWING heart WITH DOUBLE-PUMP ANIMATION
                    // ==========================================
                    FadeTransition(
                      opacity: _heartFadeAnimation,
                      child: ScaleTransition(
                        scale: _heartScaleAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Soft radial shadow behind the heart
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 140.w,
                                  height: 140.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFB3C6).withValues(alpha: 0.28 * _glowIntensityAnimation.value),
                                        blurRadius: 42.r + (16.r * _glowIntensityAnimation.value),
                                        spreadRadius: 2.w + (6.w * _glowIntensityAnimation.value),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),

                            // 2. Mathematically perfect, gorgeous gradient heart silhouette
                            ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color(0xFFFFB3C6), // Sweet pastel warm pink
                                    Color(0xFFFFC6FF), // Soft lavender pink
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: Icon(
                                Icons.favorite_rounded,
                                size: 120.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 52.h),

                    // ==========================================
                    // BRAND TYPOGRAPHY & TAGLINE (FADE IN)
                    // ==========================================
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _titleFadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _titleSlideAnimation.value),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          // Brand Name: Serif, sleek, tightly spaced
                          Text(
                            "BaeWindow",
                            style: TextStyle(
                              fontFamily: 'serif', // Aesthetic serif font
                              color: Colors.white,
                              fontSize: 38.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          
                          // Tagline: Cursive/Italic warm gray
                          AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _subtitleFadeAnimation.value,
                                child: child,
                              );
                            },
                            child: Text(
                              "just a glance away",
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFFCCCCCC), // Muted premium gray
                                fontSize: 16.sp,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // FOOTER BRANDING: "MADE FOR TWO" (BOTTOM)
              // ==========================================
              Positioned(
                bottom: 50.h,
                child: AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _footerFadeAnimation.value,
                      child: child,
                    );
                  },
                  child: Text(
                    "MADE FOR TWO",
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      color: const Color(0xFF888888), // Muted dark-charcoal gray
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4.5.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

