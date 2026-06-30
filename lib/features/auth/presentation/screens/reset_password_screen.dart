import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/common_widgets/custom_auth_text_field.dart';
import 'package:bea_window_app/common_widgets/custom_auth_button.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import '../widgets/auth_background_blobs.dart';
import '../widgets/auth_header.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isLoading = false;

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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      // Mock Reset Password API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Password reset successfully! Please sign in with your new password.'),
            backgroundColor: const Color(0xFF4CD964),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.loginScreen,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
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
                        SizedBox(height: 36.h),
                        const AuthHeader(
                          logoIcon: Icons.vpn_key_outlined,
                          eyebrow: 'Create New Credentials',
                          headline: 'Reset Password ✦',
                          subtitle: 'Ensure your new password contains at least 6 characters and matches in both fields.',
                        ),
                        SizedBox(height: 32.h),
                        CustomAuthTextField(
                          controller: _newPasswordController,
                          hintText: 'New Password',
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomAuthTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          prefixIcon: Icons.lock_clock_outlined,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 28.h),
                        CustomAuthButton(
                          label: 'Reset Password',
                          isLoading: _isLoading,
                          onTap: _handleResetPassword,
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
  }


}
