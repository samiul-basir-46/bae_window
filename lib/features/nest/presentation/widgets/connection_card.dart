import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/common_widgets/floating_bubbles_background.dart';
import '../bloc/nest_bloc.dart';
import '../bloc/nest_event.dart';

class ConnectionCard extends StatefulWidget {
  final String partnerName;
  final bool isLeftAvatarOnTop;
  final VoidCallback onTap;
  final bool isPaired;
  final String userAvatarUrl;
  final String partnerAvatarUrl;

  const ConnectionCard({
    super.key,
    required this.partnerName,
    required this.isLeftAvatarOnTop,
    required this.onTap,
    required this.isPaired,
    required this.userAvatarUrl,
    required this.partnerAvatarUrl,
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
      final isPastHalfway = _controller.value >= 0.5;
      if (isPastHalfway != !_isLeftOnTop) {
        setState(() {
          _isLeftOnTop = !isPastHalfway;
        });
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
    if (!widget.isPaired) return;
    if (_controller.isAnimating) return;
    context.read<NestBloc>().add(const SwapConnectionAvatarsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final Widget cardContent = Padding(
      padding: EdgeInsets.all(20.r),
      child: Row(
        children: [
          GestureDetector(
            onTap: _triggerCircleSwap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 72.w,
              height: 48.h,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final sep = _separationAnimation.value;

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

                    // Circle A (Left, User Avatar)
                    final Widget leftCircle = Positioned(
                      left: 0.w - sep,
                      child: Transform.scale(
                        scale: leftScale,
                        child: Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.r),
                            child: widget.userAvatarUrl.isNotEmpty
                                ? Image.network(
                                    widget.userAvatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, e, s) => Container(
                                      color: const Color(0xFF9868FF),
                                      child: Icon(Icons.person_rounded,
                                          color: Colors.white, size: 20.sp),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF9868FF),
                                    child: Icon(Icons.person_rounded,
                                        color: Colors.white, size: 20.sp),
                                  ),
                          ),
                        ),
                      ),
                    );

                    final Widget rightCircle = Positioned(
                      left: 24.w + sep,
                      child: Transform.scale(
                        scale: rightScale,
                        child: Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.softBlack, width: 2.w),
                            boxShadow: !_isLeftOnTop && widget.isPaired
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.r),
                            child: widget.isPaired
                                ? (widget.partnerAvatarUrl.isNotEmpty
                                    ? Image.network(
                                        widget.partnerAvatarUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, e, s) =>
                                            Container(
                                          color: const Color(0xFFFF6E7F),
                                          child: Icon(Icons.favorite_rounded,
                                              color: Colors.white, size: 18.sp),
                                        ),
                                      )
                                    : Container(
                                        color: const Color(0xFFFF6E7F),
                                        child: Icon(Icons.favorite_rounded,
                                            color: Colors.white, size: 18.sp),
                                      ))
                                : Container(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    child: Icon(Icons.add_rounded,
                                        color: AppColors.primaryPink,
                                        size: 20.sp),
                                  ),
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
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isPaired
                      ? "You & ${widget.partnerName}"
                      : "Solo Mode",
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                UIHelper.verticalSpace(4.h),
                Text(
                  widget.isPaired
                      ? "Tap circles to swap, tap card for profile"
                      : "Connect with partner to unlock your shared space ✦",
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
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: widget.isPaired
              ? null
              : LinearGradient(
                  colors: [
                    const Color(0xFF9868FF).withValues(alpha: 0.08),
                    const Color(0xFFFF6E7F).withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: widget.isPaired ? Colors.white.withValues(alpha: 0.02) : null,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: widget.isPaired
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFFF6E7F).withValues(alpha: 0.15),
            width: 1.w,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: FloatingBubblesBackground(
            bubbleColor: const Color(0xFFFF8FB8),
            child: cardContent,
          ),
        ),
      ),
    );
  }
}
