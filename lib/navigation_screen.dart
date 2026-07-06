import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/features/home/presentation/screens/home_screens.dart';
import 'package:bea_window_app/features/story/presentation/screens/story_screen.dart';
import 'package:bea_window_app/features/space_screen/presentation/screens/space_screen.dart';
import 'package:bea_window_app/features/nest/presentation/screens/nest_screen.dart';
import 'helpers/helper_methods.dart';
import 'helpers/deep_link_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/features/space_screen/services/presence_service.dart';

class SwitchTabNotification extends Notification {
  final int index;
  const SwitchTabNotification(this.index);
}

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isNavbarVisible = true;

  // Minimal scrollable placeholder views to demonstrate hide/show on scroll
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = [
      const HomeScreen(),
      const StoryScreen(),
      const SpaceScreen(),
      const NestScreen(),
    ];
    // Start listening for widget deep links
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHelper.init(context);
    });
    // Set initial presence to online
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      PresenceService().updateUserPresence(user.uid, true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DeepLinkHelper.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isOnline = state == AppLifecycleState.resumed;
      PresenceService().updateUserPresence(user.uid, isOnline);
    }
  }


  @override
  Widget build(BuildContext context) {
    return NotificationListener<SwitchTabNotification>(
      onNotification: (notification) {
        setState(() {
          _currentIndex = notification.index;
          _isNavbarVisible = true;
        });
        return true;
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, _) async {
          showMaterialDialog(context);
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
              // Current Screen Content with Scroll Listener
              SafeArea(
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    final ScrollDirection direction = notification.direction;
                    if (direction == ScrollDirection.reverse) {
                      if (_isNavbarVisible) {
                        setState(() {
                          _isNavbarVisible = false;
                        });
                      }
                    } else if (direction == ScrollDirection.forward) {
                      if (!_isNavbarVisible) {
                        setState(() {
                          _isNavbarVisible = true;
                        });
                      }
                    }
                    return true;
                  },
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ),
              // Floating Premium Bottom Navigation Bar (Animated Show/Hide on Scroll)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                left: 24.w,
                right: 24.w,
                bottom: _isNavbarVisible ? 30.h : -90.h,
                child: _buildCustomNavBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNavBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 74.h,
          decoration: BoxDecoration(
            color: AppColors.navBgColor,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth = constraints.maxWidth / 4;
              return Stack(
                children: [
                  // Smooth sliding background pill behind active tab
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    left: _currentIndex * itemWidth + 8.w,
                    top: 10.h,
                    child: Container(
                      width: itemWidth - 16.w,
                      height: 54.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryPink.withValues(alpha: 0.15),
                            AppColors.primaryPurple.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.primaryPink.withValues(alpha: 0.15),
                          width: 1.w,
                        ),
                      ),
                    ),
                  ),
                  // Icons Row
                  Row(
                    children: [
                      _buildNavItem(0, Icons.favorite_rounded,
                          Icons.favorite_border_rounded, "Home"),
                      _buildNavItem(1, Icons.auto_stories_rounded,
                          Icons.menu_book_rounded, "Story"),
                      _buildNavItem(2, Icons.explore_rounded,
                          Icons.explore_outlined, "Spaces"),
                      _buildNavItem(3, Icons.shield_rounded,
                          Icons.shield_outlined, "Nest"),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.15 : 1.0,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 300),
                turns: isSelected && index == 0
                    ? 0.05
                    : 0.0, // Subtly tilts heart on tap
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    if (isSelected) {
                      return const LinearGradient(
                        colors: [
                          AppColors.primaryPink,
                          AppColors.primaryPurple
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    } else {
                      return LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.4),
                          Colors.white.withValues(alpha: 0.4)
                        ],
                      ).createShader(bounds);
                    }
                  },
                  blendMode: BlendMode.srcIn,
                  child: Icon(
                    isSelected ? selectedIcon : unselectedIcon,
                    size: 24.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.h),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.dmSans(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryPink
                    : Colors.white.withValues(alpha: 0.4),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
