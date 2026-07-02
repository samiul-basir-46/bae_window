import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/common_widgets/custom_auth_text_field.dart';
import 'package:bea_window_app/common_widgets/custom_auth_button.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/constants/validator.dart';
import '../widgets/auth_background_blobs.dart';
import '../widgets/auth_header.dart';
import '../bloc/auth_bloc.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _blocErrorMessage;
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
        if (state is ForgotPasswordLoading) {
          setState(() {
            _blocErrorMessage = null;
          });
        }
        if (state is ForgotPasswordSuccess) {
          AppToast.show(
            context,
            title: "Email Sent",
            message: "A password reset link has been sent to your email address.",
            type: ToastType.success,
          );
          Navigator.pop(context);
        } else if (state is ForgotPasswordFailure) {
          setState(() {
            _blocErrorMessage = state.errorMessage;
          });
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
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
                            UIHelper.verticalSpace(36.h),
                            const AuthHeader(
                              logoIcon: Icons.lock_reset_rounded,
                              eyebrow: 'Recover password',
                              headline: 'Forgot your\npassword? ✦',
                              subtitle: 'Enter the email address associated with your account, and we\'ll send you instructions to reset your password.',
                            ),
                            UIHelper.verticalSpace(32.h),
                            CustomAuthTextField(
                              controller: _emailController,
                              hintText: 'Email address',
                              prefixIcon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: emailValidator,
                            ),
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
                            UIHelper.verticalSpace(24.h),
                            CustomAuthButton(
                              label: 'Send Reset Link',
                              isLoading: isLoading,
                              onTap: _handleReset,
                            ),
                            UIHelper.verticalSpace(32.h),
                            _buildBottomLink(
                              prefix: "Remembered? ",
                              action: "Sign in →",
                              onTap: () => Navigator.pop(context),
                            ),
                            UIHelper.verticalSpace(24.h),
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
