import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/common_widgets/custom_auth_text_field.dart';
import '../bloc/auth_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isSuccessState = false;

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
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _handleReset() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            ForgotPasswordRequestedEvent(_emailController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ForgotPasswordSuccess) {
          setState(() {
            _isSuccessState = true;
          });
        } else if (state is ForgotPasswordFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: const Color(0xFFB03085),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ForgotPasswordLoading;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D10),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          extendBodyBehindAppBar: true,
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 36.h),
                            _buildLogoMark(),
                            SizedBox(height: 24.h),
                            if (!_isSuccessState) ...[
                              _buildEyebrow('Recover password'),
                              SizedBox(height: 6.h),
                              _buildHeadline('Forgot your\npassword? ✦'),
                              SizedBox(height: 8.h),
                              _buildSubtitle(
                                'Enter the email address associated with your account, and we\'ll send you instructions to reset your password.',
                              ),
                              SizedBox(height: 32.h),
                              CustomAuthTextField(
                                controller: _emailController,
                                hintText: 'Email address',
                                prefixIcon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email address';
                                  }
                                  final emailRegex = RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 24.h),
                              _buildPrimaryButton(
                                label: 'Send Reset Link',
                                isLoading: isLoading,
                                onTap: _handleReset,
                              ),
                            ] else ...[
                              _buildEyebrow('Check your inbox'),
                              SizedBox(height: 6.h),
                              _buildHeadline('Reset link sent! ✦'),
                              SizedBox(height: 8.h),
                              _buildSubtitle(
                                'We have sent password reset instructions to:\n${_emailController.text.trim()}',
                              ),
                              SizedBox(height: 36.h),
                              _buildSuccessCheckmark(),
                              SizedBox(height: 36.h),
                              _buildPrimaryButton(
                                label: 'Back to Login',
                                isLoading: false,
                                onTap: () => Navigator.pop(context),
                              ),
                            ],
                            SizedBox(height: 32.h),
                            if (!_isSuccessState)
                              _buildBottomLink(
                                prefix: "Remembered? ",
                                action: "Sign in →",
                                onTap: () => Navigator.pop(context),
                              ),
                            SizedBox(height: 24.h),
                          ],
                        ),
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
    return Stack(
      children: [
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
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF8FB8).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
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
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF8250DC).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
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
        child: Icon(Icons.lock_reset_rounded, color: Colors.white, size: 28.sp),
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


  Widget _buildSuccessCheckmark() {
    return Container(
      width: 72.w,
      height: 72.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF4CD964).withValues(alpha: 0.1),
        border: Border.all(color: const Color(0xFF4CD964).withValues(alpha: 0.3), width: 2),
      ),
      child: Center(
        child: Icon(
          Icons.check_circle_outline_rounded,
          color: const Color(0xFF4CD964),
          size: 40.sp,
        ),
      ),
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
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
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
            fontSize: 13.sp,
            color: const Color(0xFF555568),
          ),
          children: [
            TextSpan(
              text: action,
              style: GoogleFonts.dmSans(
                color: const Color(0xFFE060A0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
