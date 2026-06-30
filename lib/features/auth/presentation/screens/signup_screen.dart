import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/common_widgets/custom_auth_text_field.dart';
import '../../../../gen/assets.gen.dart';
import '../bloc/auth_bloc.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  int _passwordStrength = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

    _passwordController.addListener(_checkPasswordStrength);
  }

  void _checkPasswordStrength() {
    final pw = _passwordController.text;
    int strength = 0;
    if (pw.length >= 6) strength++;
    if (pw.length >= 10) strength++;
    if (pw.contains(RegExp(r'[A-Z]')) && pw.contains(RegExp(r'[0-9]')))
      strength++;
    if (pw.contains(RegExp(r'[!@#\$&*~]'))) strength++;
    setState(() => _passwordStrength = strength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Color get _strengthColor {
    if (_passwordStrength <= 1) return const Color(0xFFE060A0);
    if (_passwordStrength == 2) return const Color(0xFFF5A623);
    return const Color(0xFF4CD964);
  }

  String get _strengthLabel {
    if (_passwordStrength == 0) return '';
    if (_passwordStrength <= 1) return 'Weak';
    if (_passwordStrength == 2) return 'Fair';
    if (_passwordStrength == 3) return 'Good';
    return 'Strong ✦';
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
              _buildBlobs(),
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
                          SizedBox(height: 48.h),
                          _buildLogoMark(),
                          SizedBox(height: 20.h),
                          _buildEyebrow('New beginning'),
                          SizedBox(height: 6.h),
                          _buildHeadline('Create your\nwindow ✦'),
                          SizedBox(height: 8.h),
                          _buildSubtitle(
                              'Just for the two of you — private & precious.'),
                          SizedBox(height: 32.h),
                          CustomAuthTextField(
                            controller: _nameController,
                            hintText: 'Your name',
                            prefixIcon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.name,
                          ),
                          SizedBox(height: 12.h),
                          CustomAuthTextField(
                            controller: _emailController,
                            hintText: 'Email address',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 12.h),
                          CustomAuthTextField(
                            controller: _passwordController,
                            hintText: 'Create password',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),
                          SizedBox(height: 10.h),
                          _buildStrengthBar(),
                          SizedBox(height: 20.h),
                          _buildPrimaryButton(
                            label: 'Create Account',
                            isLoading: isLoading,
                            onTap: () {},
                          ),
                          SizedBox(height: 20.h),
                          _buildOrDivider(),
                          SizedBox(height: 16.h),
                          _buildGoogleButton(context, isLoading),
                          if (Platform.isIOS) ...[
                            SizedBox(height: 10.h),
                            _buildAppleButton(context, isLoading),
                          ],
                          SizedBox(height: 16.h),
                          _buildTerms(),
                          SizedBox(height: 16.h),
                          _buildBottomLink(
                            prefix: 'Already have an account? ',
                            action: 'Sign In →',
                            onTap: () => Navigator.pushReplacementNamed(
                              context,
                              Routes.loginScreen,
                            ),
                          ),
                          SizedBox(height: 28.h),
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

  Widget _buildBlobs() {
    return Stack(children: [
      Positioned(
        top: -80,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            width: 300.w,
            height: 300.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFFF8FB8).withValues(alpha: 0.15),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 100.h,
        right: -40.w,
        child: Container(
          width: 200.w,
          height: 200.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFF8250DC).withValues(alpha: 0.1),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildLogoMark() {
    return Container(
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8FB8), Color(0xFFD94E98), Color(0xFFB03085)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB03085).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.favorite_rounded, color: Colors.white, size: 26.sp),
      ),
    );
  }

  Widget _buildEyebrow(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFE060A0),
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildHeadline(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.playfairDisplay(
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.25,
      ),
    );
  }

  Widget _buildSubtitle(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.dmSans(
        fontSize: 13.sp,
        color: const Color(0xFF6B6B80),
        height: 1.6,
      ),
    );
  }



  Widget _buildStrengthBar() {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3.h,
                margin: EdgeInsets.only(right: i < 3 ? 4.w : 0),
                decoration: BoxDecoration(
                  color: i < _passwordStrength
                      ? _strengthColor
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            );
          }),
        ),
        if (_strengthLabel.isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(
            _strengthLabel,
            style: GoogleFonts.dmSans(
                fontSize: 11.sp,
                color: _strengthColor,
                fontWeight: FontWeight.w500),
          ),
        ]
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8FB8), Color(0xFFD94E98), Color(0xFFB03085)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB03085).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  '$label →',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
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
        child: Text('or sign up with',
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
            SizedBox(width: 10.w),
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
            Icon(Icons.apple, color: Colors.white, size: 20.sp),
            SizedBox(width: 10.w),
            Text('Sign up with Apple',
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

  Widget _buildTerms() {
    return Text.rich(
      TextSpan(
        text: 'By continuing you agree to our ',
        style: GoogleFonts.dmSans(
            fontSize: 11.sp, color: const Color(0xFF3A3A4A), height: 1.5),
        children: const [
          TextSpan(text: 'Terms', style: TextStyle(color: Color(0xFF8060C8))),
          TextSpan(text: ' & '),
          TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(color: Color(0xFF8060C8))),
        ],
      ),
      textAlign: TextAlign.center,
    );
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
