import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/nest_bloc.dart';
import '../bloc/nest_event.dart';

class ConnectionCard extends StatefulWidget {
  final String partnerName;
  final bool isLeftAvatarOnTop;
  final VoidCallback onTap;

  const ConnectionCard({
    super.key,
    required this.partnerName,
    required this.isLeftAvatarOnTop,
    required this.onTap,
  });

  @override
  State<ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<ConnectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _separationAnimation;

  late bool _isLeftOnTop;

  @override
  void initState() {
    super.initState();
    _isLeftOnTop = widget.isLeftAvatarOnTop;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Moves outward by 16.w and back to 0
    _separationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 16.w)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 16.w, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.addListener(() {
      // Swap z-index at the peak (0.5 progress) of separation
      if (_controller.value >= 0.48 && _controller.value <= 0.52) {
        if (_controller.status == AnimationStatus.forward && _isLeftOnTop) {
          setState(() {
            _isLeftOnTop = false;
          });
        } else if (_controller.status == AnimationStatus.reverse &&
            !_isLeftOnTop) {
          setState(() {
            _isLeftOnTop = true;
          });
        }
      }
    });

    // If starting off-center (false), set controller to 1.0
    if (!_isLeftOnTop) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant ConnectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLeftAvatarOnTop != oldWidget.isLeftAvatarOnTop) {
      if (widget.isLeftAvatarOnTop) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerCircleSwap() {
    if (_controller.isAnimating) return;
    context.read<NestBloc>().add(const SwapConnectionAvatarsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            // Interlocking Gradient Circles with Swap Animation
            GestureDetector(
              onTap: _triggerCircleSwap,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 72.w,
                height: 48.h,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final sep = _separationAnimation.value;

                    // Dynamic scaling for 3D orbiting effect
                    double leftScale = 1.0;
                    double rightScale = 1.0;

                    if (_controller.isAnimating) {
                      final double progress =
                          1.0 - (2 * (_controller.value - 0.5).abs());
                      if (_controller.status == AnimationStatus.forward) {
                        leftScale = 1.0 - (0.15 * progress);
                        rightScale = 1.0 + (0.15 * progress);
                      } else {
                        leftScale = 1.0 + (0.15 * progress);
                        rightScale = 1.0 - (0.15 * progress);
                      }
                    }

                    // Circle A (Left, Blue/Purple)
                    final Widget leftCircle = Positioned(
                      left: 0.w - sep,
                      child: Transform.scale(
                        scale: leftScale,
                        child: Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6A82FF), Color(0xFF9868FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                                color: AppColors.softBlack, width: 2.w),
                            boxShadow: _isLeftOnTop
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF9868FF)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );

                    // Circle B (Right, Pink/Blue)
                    final Widget rightCircle = Positioned(
                      left: 24.w + sep,
                      child: Transform.scale(
                        scale: rightScale,
                        child: Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6E7F), Color(0xFFBFE9FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                                color: AppColors.softBlack, width: 2.w),
                            boxShadow: !_isLeftOnTop
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF6E7F)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );

                    return Stack(
                      clipBehavior: Clip.none,
                      children: _isLeftOnTop
                          ? [rightCircle, leftCircle]
                          : [leftCircle, rightCircle],
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You & ${widget.partnerName}",
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  UIHelper.verticalSpace(4.h),
                  Text(
                    "Tap circles to swap, tap card for profile",
                    style: GoogleFonts.dmSans(
                      color: Colors.white38,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
