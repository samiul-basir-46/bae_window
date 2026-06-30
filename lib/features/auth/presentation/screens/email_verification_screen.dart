import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/common_widgets/custom_auth_button.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../widgets/auth_background_blobs.dart';
import '../widgets/auth_header.dart';
import '../bloc/auth_bloc.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  Timer? _cooldownTimer;
  int _secondsRemaining = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

    _startCooldown(60); // 60 seconds cooldown initially
  }

  void _startCooldown(int seconds) {
    setState(() {
      _secondsRemaining = seconds;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _cooldownTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _checkVerification() {
    context.read<AuthBloc>().add(const CheckEmailVerificationRequested());
  }

  void _resendEmail() {
    if (_secondsRemaining == 0) {
      context.read<AuthBloc>().add(const ResendVerificationEmailRequested());
      _startCooldown(60); // Reset 60s cooldown
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is EmailVerificationPending) {
          setState(() {
            _errorMessage = null;
          });
        } else if (state is EmailVerificationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  const Text("Email verified successfully! Welcome."),
                ],
              ),
              backgroundColor: const Color(0xFF4CD964),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pushReplacementNamed(context, Routes.navigationScreen);
        } else if (state is EmailVerificationFailure) {
          setState(() {
            _errorMessage = state.errorMessage;
          });
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D10),
          body: Stack(
            children: [
              const AuthBackgroundBlobs(),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 28.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          UIHelper.verticalSpace(52.h),
                          const AuthHeader(
                            logoIcon: Icons.mark_email_read_outlined,
                            eyebrow: 'Verify Email Address',
                            headline: 'Verify your\nemail ✦',
                            subtitle: 'We have sent a verification link to your email. Please check your inbox and click the link to verify your account, then click the button below.',
                          ),
                          UIHelper.verticalSpace(40.h),
                          CustomAuthButton(
                            label: "I've Verified",
                            isLoading: isLoading,
                            onTap: _checkVerification,
                          ),
                          UIHelper.verticalSpace(20.h),
                          _buildResendButton(),
                          if (_errorMessage != null) ...[
                            UIHelper.verticalSpace(16.h),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFFE060A0),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          UIHelper.verticalSpace(40.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResendButton() {
    final canResend = _secondsRemaining == 0;
    return GestureDetector(
      onTap: canResend ? _resendEmail : null,
      child: Container(
        height: 52.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: canResend
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.02),
          ),
        ),
        child: Center(
          child: Text(
            canResend
                ? 'Resend Email'
                : 'Resend in ${_secondsRemaining.toString().padLeft(2, '0')}s',
            style: GoogleFonts.dmSans(
              color: canResend ? const Color(0xFF9090A8) : const Color(0xFF555568),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
