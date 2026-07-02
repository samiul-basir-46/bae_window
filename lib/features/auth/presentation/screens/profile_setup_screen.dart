import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bea_window_app/common_widgets/custom_auth_button.dart';
import 'package:bea_window_app/common_widgets/custom_auth_text_field.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../widgets/auth_background_blobs.dart';
import '../widgets/auth_header.dart';
import '../bloc/auth_bloc.dart';
import 'package:bea_window_app/helpers/di.dart';
import 'package:bea_window_app/features/email/presentation/cubit/email_cubit.dart';
import 'package:bea_window_app/features/email/data/templates/welcome_email_template.dart';
import 'package:bea_window_app/common_widgets/custom_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  File? _selectedLocalFile;
  String? _selectedPredefinedUrl;
  String? _errorMessage;

  final List<String> _predefinedAvatars = [
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
    'https://i.pravatar.cc/150?img=2',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
  ];

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

    // Default selection
    _selectedPredefinedUrl = _predefinedAvatars.first;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null) {
        setState(() {
          _selectedLocalFile = File(picked.path);
          _selectedPredefinedUrl = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to pick image: $e";
      });
    }
  }

  void _onContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            SaveProfileRequested(
              nickname: _nicknameController.text.trim(),
              avatarUrl: _selectedPredefinedUrl,
              avatarFile: _selectedLocalFile,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EmailCubit>(
      create: (context) => locator<EmailCubit>(),
      child: BlocConsumer<EmailCubit, EmailState>(
        listener: (context, emailState) {
          if (emailState.status == EmailStatus.success) {
            customToastMessage('Success', 'Welcome email sent successfully!');
            Navigator.pushReplacementNamed(context, Routes.pairingScreen);
          } else if (emailState.status == EmailStatus.failure) {
            customToastMessage('Notice', emailState.errorMessage ?? 'Failed to send welcome email.');
            // Still navigate so the user isn't blocked
            Navigator.pushReplacementNamed(context, Routes.pairingScreen);
          }
        },
        builder: (context, emailState) {
          return BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is ProfileSetupLoading) {
                setState(() {
                  _errorMessage = null;
                });
              } else if (state is ProfileSetupSuccess) {
                final user = FirebaseAuth.instance.currentUser;
                final email = user?.email;
                if (email != null) {
                  context.read<EmailCubit>().sendEmail(
                    to: email,
                    subject: 'Welcome to Bae Window 💌',
                    htmlContent: baeWindowWelcomeEmailHtml(
                      userName: _nicknameController.text.trim(),
                    ),
                    name: _nicknameController.text.trim(),
                  );
                } else {
                  Navigator.pushReplacementNamed(context, Routes.pairingScreen);
                }
              } else if (state is ProfileSetupFailure) {
                setState(() {
                  _errorMessage = state.errorMessage;
                });
              }
            },
            builder: (context, state) {
              final isLoading = state is ProfileSetupLoading ||
                  emailState.status == EmailStatus.loading;


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
                            UIHelper.verticalSpace(40.h),
                            const AuthHeader(
                              logoIcon: Icons.person_outline_rounded,
                              eyebrow: 'Profile Customization',
                              headline: 'Setup your\nprofile ✦',
                              subtitle:
                                  'Choose an avatar or upload your own, and pick a nickname that your partner will see.',
                            ),
                            UIHelper.verticalSpace(28.h),
                            _buildAvatarSelector(),
                            UIHelper.verticalSpace(28.h),
                            CustomAuthTextField(
                              controller: _nicknameController,
                              hintText: 'Your Nickname',
                              prefixIcon: Icons.badge_outlined,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nickname is required';
                                }
                                return null;
                              },
                            ),
                            if (_errorMessage != null) ...[
                              UIHelper.verticalSpace(14.h),
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
                            UIHelper.verticalSpace(32.h),
                            CustomAuthButton(
                              label: 'Continue',
                              isLoading: isLoading,
                              onTap: _onContinue,
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
        },
      ),
    );
  }




  Widget _buildAvatarSelector() {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2.sp),
                  image: _selectedLocalFile != null
                      ? DecorationImage(
                          image: FileImage(_selectedLocalFile!),
                          fit: BoxFit.cover,
                        )
                      : (_selectedPredefinedUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_selectedPredefinedUrl!),
                              fit: BoxFit.cover,
                            )
                          : null),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8060C8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        UIHelper.verticalSpace(20.h),
        Text(
          'Or choose a predefined avatar:',
          style: GoogleFonts.dmSans(
            color: Colors.white54,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        UIHelper.verticalSpace(12.h),
        SizedBox(
          height: 52.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: _predefinedAvatars.length,
            separatorBuilder: (context, index) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final url = _predefinedAvatars[index];
              final isSelected = _selectedPredefinedUrl == url;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPredefinedUrl = url;
                    _selectedLocalFile = null;
                  });
                },
                child: Container(
                  width: 50.r,
                  height: 50.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8060C8)
                          : Colors.transparent,
                      width: 2.5.sp,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
