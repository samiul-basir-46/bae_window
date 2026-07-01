import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/constants/app_constants.dart';
import 'package:bea_window_app/helpers/di.dart';
import '../widgets/auth_background_blobs.dart';
import '../bloc/email_verification_cubit.dart';
import '../bloc/email_verification_state.dart';

class VerifyingScreen extends StatefulWidget {
  final String token;
  final String uid;

  const VerifyingScreen({
    super.key,
    required this.token,
    required this.uid,
  });

  @override
  State<VerifyingScreen> createState() => _VerifyingScreenState();
}

class _VerifyingScreenState extends State<VerifyingScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<EmailVerificationCubit>(
      create: (context) => EmailVerificationCubit()..verifyToken(uid: widget.uid, token: widget.token),
      child: const VerifyingView(),
    );
  }
}

class VerifyingView extends StatelessWidget {
  const VerifyingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D10),
      body: Stack(
        children: [
          const AuthBackgroundBlobs(),
          SafeArea(
            child: BlocConsumer<EmailVerificationCubit, EmailVerificationState>(
              listener: (context, state) {
                if (state is EmailVerificationVerified) {
                  appData.write(kKeyIsLoggedIn, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20.sp),
                          SizedBox(width: 8.w),
                          const Text("Verification success! Welcome."),
                        ],
                      ),
                      backgroundColor: const Color(0xFF4CD964),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routes.profileSetupScreen,
                    (route) => false,
                  );
                }
              },
              builder: (context, state) {
                if (state is EmailVerificationVerifying) {
                  return _buildStatusContent(
                    icon: Icons.hourglass_empty_rounded,
                    iconColor: AppColors.primaryPink,
                    title: "Verifying Email...",
                    subtitle: "Please wait a moment while we validate your secure token.",
                    showLoading: true,
                  );
                } else if (state is EmailVerificationFailed) {
                  return _buildStatusContent(
                    icon: Icons.error_outline_rounded,
                    iconColor: Colors.redAccent,
                    title: "Verification Failed",
                    subtitle: state.errorMessage,
                    showLoading: false,
                    action: _buildButton(
                      label: "Back to Login",
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.loginScreen,
                          (route) => false,
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool showLoading,
    Widget? action,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 48.sp),
            ),
            UIHelper.verticalSpace(24.h),
            Text(
              title,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            UIHelper.verticalSpace(12.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: Colors.white38,
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
            if (showLoading) ...[
              UIHelper.verticalSpace(36.h),
              const CircularProgressIndicator(color: AppColors.primaryPink),
            ],
            if (action != null) ...[
              UIHelper.verticalSpace(36.h),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: const LinearGradient(
            colors: [AppColors.primaryPink, AppColors.primaryPurple],
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
