import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/common_widgets/custom_auth_button.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../widgets/auth_background_blobs.dart';
import '../widgets/auth_header.dart';
import '../bloc/email_verification_cubit.dart';
import '../bloc/email_verification_state.dart';
import 'package:bea_window_app/helpers/di.dart';
import 'package:bea_window_app/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EmailVerificationCubit>(
      create: (context) {
        final cubit = EmailVerificationCubit();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          cubit.sendVerificationEmail(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'Partner',
          );
        }
        return cubit;
      },
      child: const EmailVerificationView(),
    );
  }
}

class EmailVerificationView extends StatefulWidget {
  const EmailVerificationView({super.key});

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
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
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _checkVerification() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<EmailVerificationCubit>().checkVerificationStatus(uid: user.uid);
    }
  }

  void _resendEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<EmailVerificationCubit>().sendVerificationEmail(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'Partner',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final emailAddress = user?.email ?? 'your email';

    return BlocConsumer<EmailVerificationCubit, EmailVerificationState>(
      listener: (context, state) {
        if (state is EmailVerificationVerified) {
          appData.write(kKeyIsLoggedIn, true);
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
          Navigator.pushReplacementNamed(context, Routes.profileSetupScreen);
        } else if (state is EmailVerificationFailed) {
          setState(() {
            _errorMessage = state.errorMessage;
          });
        } else {
          setState(() {
            _errorMessage = null;
          });
        }
      },
      builder: (context, state) {
        final isLoading = state is EmailVerificationVerifying || state is EmailVerificationSending;

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
                          AuthHeader(
                            logoIcon: Icons.mark_email_read_outlined,
                            eyebrow: 'Verify Email Address',
                            headline: 'Verify your\nemail ✦',
                            subtitle:
                                'We have sent a verification link to $emailAddress using Brevo. Please check your inbox and click the link to verify your account, then click the button below.',
                          ),
                          UIHelper.verticalSpace(40.h),
                          CustomAuthButton(
                            label: "I've Verified",
                            isLoading: isLoading,
                            onTap: _checkVerification,
                          ),
                          UIHelper.verticalSpace(20.h),
                          _buildResendButton(state),
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
                          UIHelper.verticalSpace(28.h),
                          GestureDetector(
                            onTap: () async {
                              final navigator = Navigator.of(context);
                              try {
                                await FirebaseAuth.instance.signOut();
                                appData.write(kKeyIsLoggedIn, false);
                                navigator.pushNamedAndRemoveUntil(
                                  Routes.loginScreen,
                                  (route) => false,
                                );
                              } catch (e) {
                                setState(() {
                                  _errorMessage = "Failed to sign out: $e";
                                });
                              }
                            },
                            child: Text(
                              "Wrong email address? Go back",
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF9090A8),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
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

  Widget _buildResendButton(EmailVerificationState state) {
    final int cooldownSeconds = state is EmailVerificationCooldown ? state.secondsRemaining : 0;
    final canResend = cooldownSeconds == 0 && state is! EmailVerificationSending;

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
                : 'Resend in ${cooldownSeconds.toString().padLeft(2, '0')}s',
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
