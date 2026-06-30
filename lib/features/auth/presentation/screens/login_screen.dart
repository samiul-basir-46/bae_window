import 'dart:io';
import 'package:bea_window_app/helpers/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/common_widgets/custom_auth_text_field.dart';
import 'package:bea_window_app/common_widgets/custom_auth_button.dart';
import '../widgets/auth_background_blobs.dart';
import '../widgets/auth_header.dart';
import '../../../../gen/assets.gen.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

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
    _emailController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.pushReplacementNamed(context, '/couple_link');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: const Color(0xFFB03085),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
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
                            logoIcon: Icons.favorite_rounded,
                            eyebrow: 'Welcome back',
                            headline: 'Your window\nawaits ✦',
                            subtitle: 'Sign in to reconnect with your person.',
                          ),
                          UIHelper.verticalSpace(32.h),
                           CustomAuthTextField(
                            controller: _emailController,
                            hintText: 'Email address',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          UIHelper.verticalSpace(12.h),
                          CustomAuthTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),
                          UIHelper.verticalSpace(8.h),
                          _buildForgotPassword(),
                          UIHelper.verticalSpace(20.h),
                          CustomAuthButton(
                            label: 'Sign In',
                            isLoading: isLoading,
                            showArrow: true,
                            onTap: () {
                              NavigationService.navigateToUntilReplacement(
                                  Routes.navigationScreen);
                            },
                          ),
                          UIHelper.verticalSpace(20.h),
                          _buildOrDivider(),
                          UIHelper.verticalSpace(16.h),
                          _buildGoogleButton(context, isLoading),
                          if (Platform.isIOS) ...[
                            UIHelper.verticalSpace(10.h),
                            _buildAppleButton(context, isLoading),
                          ],
                          UIHelper.verticalSpace(32.h),
                          _buildBottomLink(
                            prefix: "New here? ",
                            action: "Create your window →",
                            onTap: () => Navigator.pushReplacementNamed(
                              context,
                              Routes.signUpScreen,
                            ),
                          ),
                          UIHelper.verticalSpace(24.h),
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





  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, Routes.forgotPasswordScreen),
        child: Text(
          'Forgot password?',
          style: GoogleFonts.dmSans(
            fontSize: 12.sp,
            color: const Color(0xFFE060A0),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }



  Widget _buildOrDivider() {
    return Row(children: [
      Expanded(
          child: Divider(
              color: Colors.white.withValues(alpha: 0.06), thickness: 1)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Text('or continue with',
            style: GoogleFonts.dmSans(
                fontSize: 11.sp, color: const Color(0xFF3A3A4A))),
      ),
      Expanded(
          child: Divider(
              color: Colors.white.withValues(alpha: 0.06), thickness: 1)),
    ]);
  }

  Widget _buildGoogleButton(BuildContext context, bool isLoading) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () =>
              context.read<AuthBloc>().add(const GoogleSignInRequestedEvent()),
      child: _socialButton(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              Assets.icons.google.path,
              height: 24.h,
              width: 24.w,
            ),
            UIHelper.horizontalSpace(10.w),
            Text('Continue with Google',
                style: GoogleFonts.dmSans(
                    color: const Color(0xFF9090A8),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleButton(BuildContext context, bool isLoading) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () =>
              context.read<AuthBloc>().add(const AppleSignInRequestedEvent()),
      child: _socialButton(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _appleLogo(),
            UIHelper.horizontalSpace(10.w),
            Text('Continue with Apple',
                style: GoogleFonts.dmSans(
                    color: const Color(0xFF9090A8),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _socialButton({required Widget child}) {
    return Container(
      height: 48.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _appleLogo() {
    return Icon(Icons.apple, color: Colors.white, size: 20.sp);
  }

  Widget _buildBottomLink({
    required String prefix,
    required String action,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        text: TextSpan(
          text: prefix,
          style: GoogleFonts.dmSans(
              fontSize: 13.sp, color: const Color(0xFF555568)),
          children: [
            TextSpan(
              text: action,
              style: GoogleFonts.dmSans(
                  color: const Color(0xFFE060A0), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
