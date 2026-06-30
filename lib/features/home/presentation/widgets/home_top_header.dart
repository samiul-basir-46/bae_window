import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/helpers/all_routes.dart';

class HomeTopHeader extends StatelessWidget {
  final String userAvatarUrl;
  final String? partnerAvatarUrl;
  final String? partnerName;
  final bool? isPartnerOnline;
  final int? daysTogether;
  final bool isPaired;

  const HomeTopHeader({
    super.key,
    required this.userAvatarUrl,
    required this.isPaired,
    this.partnerAvatarUrl,
    this.partnerName,
    this.isPartnerOnline,
    this.daysTogether,
  });

  Future<void> _selectRelationshipDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryPink,
              onPrimary: Colors.white,
              surface: AppColors.navBgColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formattedDate = DateFormat('MMM d, yyyy').format(picked);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseAuthService().updateUserProfile(uid, relationshipStartDate: formattedDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // User Avatar
            _buildAvatar(
              url: userAvatarUrl,
              fallbackIcon: Icons.person_rounded,
            ),

            UIHelper.horizontalSpace(16.w),

            const PulseHeartWidget(),

            UIHelper.horizontalSpace(16.w),

            // Partner Avatar or Invite CTA
            if (isPaired && partnerAvatarUrl != null)
              BreathingGlowAvatar(
                avatarUrl: partnerAvatarUrl!,
                isOnline: isPartnerOnline ?? false,
              )
            else
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, Routes.pairingScreen);
                },
                child: _buildInviteAvatar(),
              ),
          ],
        ),
        UIHelper.verticalSpace(12.h),
        GestureDetector(
          onTap: () {
            if (!isPaired) {
              Navigator.pushNamed(context, Routes.pairingScreen);
            } else if (daysTogether == null) {
              _selectRelationshipDate(context);
            }
          },
          child: Opacity(
            opacity: 0.6,
            child: Text(
              isPaired
                  ? (daysTogether != null
                      ? "$daysTogether Days Together ❤️"
                      : "Set Anniversary Date 📅")
                  : "Solo Mode ✦ Invite your partner",
              style: GoogleFonts.dmSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar({required String url, required IconData fallbackIcon}) {
    return Container(
      width: 64.w,
      height: 64.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.r),
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.navBgColor,
                  child: Icon(
                    fallbackIcon,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 28.sp,
                  ),
                ),
              )
            : Container(
                color: AppColors.navBgColor,
                child: Icon(
                  fallbackIcon,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 28.sp,
                ),
              ),
      ),
    );
  }

  Widget _buildInviteAvatar() {
    return Container(
      width: 64.w,
      height: 64.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryPink.withValues(alpha: 0.3),
          width: 2.w,
        ),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPink.withValues(alpha: 0.08),
            AppColors.primaryPurple.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person_add_rounded,
        color: AppColors.primaryPink.withValues(alpha: 0.6),
        size: 26.sp,
      ),
    );
  }
}

class BreathingGlowAvatar extends StatefulWidget {
  final String avatarUrl;
  final bool isOnline;

  const BreathingGlowAvatar({
    super.key,
    required this.avatarUrl,
    required this.isOnline,
  });

  @override
  State<BreathingGlowAvatar> createState() => _BreathingGlowAvatarState();
}

class _BreathingGlowAvatarState extends State<BreathingGlowAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _glowAnimation = Tween<double>(begin: 1.5, end: 5.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOutSine,
      ),
    );

    if (widget.isOnline) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BreathingGlowAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (!widget.isOnline && _glowController.isAnimating) {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 64.w,
          height: 64.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: widget.isOnline
                ? [
                    BoxShadow(
                      color: AppColors.primaryPink.withValues(alpha: 0.4),
                      blurRadius: _glowAnimation.value * 2,
                      spreadRadius: _glowAnimation.value / 2,
                    ),
                  ]
                : [],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isOnline
                    ? AppColors.primaryPink.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.15),
                width: 2.w,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32.r),
              child: widget.avatarUrl.isNotEmpty
                  ? Image.network(
                      widget.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.navBgColor,
                        child: Icon(
                          Icons.person_3_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 28.sp,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.navBgColor,
                      child: Icon(
                        Icons.person_3_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 28.sp,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class PulseHeartWidget extends StatefulWidget {
  const PulseHeartWidget({super.key});

  @override
  State<PulseHeartWidget> createState() => _PulseHeartWidgetState();
}

class _PulseHeartWidgetState extends State<PulseHeartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 25),
    ]).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return SizedBox(
          width: 54.w,
          height: 54.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Heartbeat waves radiating outwards
              Opacity(
                opacity: (1.0 - _waveAnimation.value) * 0.4,
                child: Container(
                  width: 32.w + (_waveAnimation.value * 22.w),
                  height: 32.h + (_waveAnimation.value * 22.h),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryPink.withValues(alpha: 0.5),
                      width: 1.5.w,
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: (1.0 - _waveAnimation.value).clamp(0.0, 1.0) * 0.2,
                child: Container(
                  width: 20.w + (_waveAnimation.value * 34.w),
                  height: 20.h + (_waveAnimation.value * 34.h),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryPurple.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                ),
              ),
              // Main heart icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.primaryPink, AppColors.primaryPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 26.sp,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
