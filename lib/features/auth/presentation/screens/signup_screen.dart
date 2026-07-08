import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/common_widgets/custom_auth_text_field.dart';
import 'package:bea_window_app/constants/validator.dart';
import '../../../../common_widgets/custom_auth_button.dart';
import '../bloc/auth_event.dart';
import '../widgets/auth_background_blobs.dart';
import '../widgets/auth_header.dart';
import '../../../../gen/assets.gen.dart';
import '../bloc/auth_bloc.dart';
import 'package:bea_window_app/helpers/di.dart';
import 'package:bea_window_app/constants/app_constants.dart';

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
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _blocErrorMessage;
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
    if (pw.contains(RegExp(r'[A-Z]')) && pw.contains(RegExp(r'[0-9]'))) {
      strength++;
    }
    if (pw.contains(RegExp(r'[!@#\$&*~]'))) strength++;
    setState(() => _passwordStrength = strength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        if (state is SignUpLoading || state is AuthLoading) {
          setState(() {
            _blocErrorMessage = null;
          });
        }
        if (state is AuthSuccess) {
          appData.write(kKeyIsLoggedIn, true);
          Navigator.pushReplacementNamed(context, Routes.navigationScreen);
        } else if (state is ProfileSetupPendingState) {
          appData.write(kKeyIsLoggedIn, true);
          Navigator.pushReplacementNamed(context, Routes.profileSetupScreen);
        } else if (state is PairingPendingState) {
          appData.write(kKeyIsLoggedIn, true);
          Navigator.pushReplacementNamed(context, Routes.pairingScreen);
        } else if (state is AuthFailure) {
          setState(() {
            _blocErrorMessage = state.errorMessage;
          });
        } else if (state is SignUpSuccess) {
          Navigator.pushReplacementNamed(
            context,
            Routes.emailVerificationScreen,
          );
        } else if (state is SignUpFailure) {
          setState(() {
            _blocErrorMessage = state.errorMessage;
          });
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading || state is SignUpLoading;
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            UIHelper.verticalSpace(48.h),
                            const AuthHeader(
                              logoIcon: Icons.favorite_rounded,
                              eyebrow: 'New beginning',
                              headline: 'Create your\nwindow ✦',
                              subtitle:
                                  'Just for the two of you — private & precious.',
                            ),
                            UIHelper.verticalSpace(32.h),
                            CustomAuthTextField(
                              controller: _nameController,
                              hintText: 'Your name',
                              prefixIcon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                              validator: nameValidator,
                            ),
                            UIHelper.verticalSpace(12.h),
                            CustomAuthTextField(
                              controller: _emailController,
                              hintText: 'Email address',
                              prefixIcon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: emailValidator,
                            ),
                            UIHelper.verticalSpace(12.h),
                            CustomAuthTextField(
                              controller: _passwordController,
                              hintText: 'Create password',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: passwordValidator,
                            ),
                            UIHelper.verticalSpace(12.h),
                            CustomAuthTextField(
                              controller: _confirmPasswordController,
                              hintText: 'Confirm password',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: (val) => confirmPasswordValidator(
                                  val, _passwordController.text),
                            ),
                            UIHelper.verticalSpace(10.h),
                            _buildStrengthBar(),
                            if (_blocErrorMessage != null) ...[
                              UIHelper.verticalSpace(12.h),
                              Text(
                                _blocErrorMessage!,
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFFE060A0),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            UIHelper.verticalSpace(20.h),
                            CustomAuthButton(
                              label: 'Create Account',
                              isLoading: isLoading,
                              showArrow: true,
                              onTap: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _blocErrorMessage = null;
                                      });
                                      final isFormValid =
                                          _formKey.currentState?.validate() ??
                                              false;
                                      if (_nameController.text.trim().isEmpty ||
                                          _emailController.text.trim().isEmpty ||
                                          _passwordController.text.isEmpty ||
                                          _confirmPasswordController.text.isEmpty) {
                                        setState(() {
                                          _blocErrorMessage =
                                              'Please fill in all fields';
                                        });
                                      } else if (isFormValid) {
                                        context.read<AuthBloc>().add(
                                              SignUpRequestedEvent(
                                                name:
                                                    _nameController.text.trim(),
                                                email: _emailController.text
                                                    .trim(),
                                                password:
                                                    _passwordController.text,
                                              ),
                                            );
                                      }
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
                            UIHelper.verticalSpace(16.h),
                            _buildTerms(),
                            UIHelper.verticalSpace(16.h),
                            _buildBottomLink(
                              prefix: 'Already have an account? ',
                              action: 'Sign In →',
                              onTap: () => Navigator.pushReplacementNamed(
                                context,
                                Routes.loginScreen,
                              ),
                            ),
                            UIHelper.verticalSpace(28.h),
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
          UIHelper.verticalSpace(6.h),
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
            Icon(Icons.apple, color: Colors.white, size: 20.sp),
            UIHelper.horizontalSpace(10.w),
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
