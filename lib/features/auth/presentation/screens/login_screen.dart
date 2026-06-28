import 'dart:io';
import 'package:bea_window_app/helpers/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
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
  bool _obscurePassword = true;
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
              // Background blobs
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
                          SizedBox(height: 52.h),
                          _buildLogoMark(),
                          SizedBox(height: 20.h),
                          _buildEyebrow('Welcome back'),
                          SizedBox(height: 6.h),
                          _buildHeadline('Your window\nawaits ✦'),
                          SizedBox(height: 8.h),
                          _buildSubtitle(
                              'Sign in to reconnect with your person.'),
                          SizedBox(height: 32.h),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Email address',
                            icon: Icons.mail_outline_rounded,
                          ),
                          SizedBox(height: 12.h),
                          _buildPasswordField(),
                          SizedBox(height: 8.h),
                          _buildForgotPassword(),
                          SizedBox(height: 20.h),
                          _buildPrimaryButton(
                            label: 'Sign In',
                            isLoading: isLoading,
                            onTap: () {
                              NavigationService.navigateToUntilReplacement(
                                  Routes.navigationScreen);
                            },
                          ),
                          SizedBox(height: 20.h),
                          _buildOrDivider(),
                          SizedBox(height: 16.h),
                          _buildGoogleButton(context, isLoading),
                          if (Platform.isIOS) ...[
                            SizedBox(height: 10.h),
                            _buildAppleButton(context, isLoading),
                          ],
                          SizedBox(height: 32.h),
                          _buildBottomLink(
                            prefix: "New here? ",
                            action: "Create your window →",
                            onTap: () => Navigator.pushReplacementNamed(
                              context,
                              Routes.signUpScreen,
                            ),
                          ),
                          SizedBox(height: 24.h),
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
        bottom: 80.h,
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

  // ─── Logo ─────────────────────────────────────────────────────────────────
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

  // ─── Typography ───────────────────────────────────────────────────────────
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

  // ─── Fields ───────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.emailAddress,
  }) {
    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(
              color: const Color(0xFF555568), fontSize: 14.sp),
          prefixIcon: Icon(icon,
              color: Colors.white.withValues(alpha: 0.3), size: 18.sp),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: GoogleFonts.dmSans(
              color: const Color(0xFF555568), fontSize: 14.sp),
          prefixIcon: Icon(Icons.lock_outline_rounded,
              color: Colors.white.withValues(alpha: 0.3), size: 18.sp),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white.withValues(alpha: 0.3),
              size: 18.sp,
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {},
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

  // ─── Buttons ──────────────────────────────────────────────────────────────
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
            _googleLogo(),
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
            _appleLogo(),
            SizedBox(width: 10.w),
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

  Widget _googleLogo() {
    return SizedBox(
      width: 18.w,
      height: 18.w,
      child: CustomPaint(painter: _GoogleLogoPainter()),
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

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), -1.4, 2.2, true, paint);
    // Green
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), 0.8, 1.2, true, paint);
    // Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), 2.0, 1.1, true, paint);
    // Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), 3.1, 1.0, true, paint);

    // White center
    paint.color = const Color(0xFF0D0D10);
    canvas.drawCircle(Offset(s / 2, s / 2), s * 0.3, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
