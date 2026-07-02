import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/features/story/presentation/bloc/story_bloc.dart';
import 'package:bea_window_app/features/story/presentation/bloc/story_state.dart';
import 'package:local_auth/local_auth.dart';

import '../bloc/change_passcode_bloc.dart';
import '../bloc/change_passcode_event.dart';
import '../bloc/change_passcode_state.dart';
import '../widgets/passcode_dot_row.dart';
import '../widgets/passcode_keypad.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';

class ChangeVaultPasscodeScreen extends StatelessWidget {
  const ChangeVaultPasscodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storyBloc = BlocProvider.of<StoryBloc>(context, listen: false);
    final currentPin = storyBloc.state is StoryLoaded
        ? (storyBloc.state as StoryLoaded).vaultPin
        : null;
    final isBiometricsEnabled = storyBloc.state is StoryLoaded
        ? (storyBloc.state as StoryLoaded).isBiometricsEnabled
        : false;

    return BlocProvider(
      create: (_) => ChangePasscodeBloc(
        storyBloc: storyBloc,
        currentPin: currentPin,
        initialBiometricsEnabled: isBiometricsEnabled,
      ),
      child: const _ChangeVaultPasscodeView(),
    );
  }
}

class _ChangeVaultPasscodeView extends StatefulWidget {
  const _ChangeVaultPasscodeView();

  @override
  State<_ChangeVaultPasscodeView> createState() => _ChangeVaultPasscodeViewState();
}

class _ChangeVaultPasscodeViewState extends State<_ChangeVaultPasscodeView> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _biometricChecked = false;

  static const _stepTitles = [
    'Verify Current PIN',
    'Enter New PIN',
    'Confirm New PIN',
  ];

  static const _stepSubtitles = [
    'Enter your current 4-digit vault PIN',
    'Choose a strong new 4-digit PIN',
    'Re-enter the new PIN to confirm',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });
  }

  Future<void> _checkBiometrics() async {
    if (_biometricChecked) return;

    final storyBloc = context.read<StoryBloc>();
    final isBioEnabled = storyBloc.state is StoryLoaded &&
        (storyBloc.state as StoryLoaded).isBiometricsEnabled;

    if (isBioEnabled) {
      _biometricChecked = true;
      await _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (canAuthenticate) {
        final bool didAuthenticate = await _auth.authenticate(
          localizedReason: 'Verify identity to change vault PIN',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (didAuthenticate && mounted) {
          context.read<ChangePasscodeBloc>().add(const VerifyWithBiometricsSuccessEvent());
          AppToast.show(
            context,
            title: "Success",
            message: "Biometric verification successful!",
            type: ToastType.success,
          );
        }
      }
    } catch (e) {
      debugPrint("Biometric Auth Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final storyBloc = context.read<StoryBloc>();
    final isBioEnabled = storyBloc.state is StoryLoaded &&
        (storyBloc.state as StoryLoaded).isBiometricsEnabled;

    return BlocConsumer<ChangePasscodeBloc, ChangePasscodeState>(
      listener: (context, state) {
        if (state is ChangePasscodeSuccess) {
          Navigator.pop(context);
          AppToast.show(
            context,
            title: "Success",
            message: "Vault PIN updated successfully!",
            type: ToastType.success,
          );
        }
      },
      builder: (context, state) {
        if (state is! ChangePasscodeStep) return const SizedBox.shrink();

        final step = state.step;
        final titleIndex = step - 1;

        return Scaffold(
          backgroundColor: AppColors.softBlack,
          body: Stack(
            children: [
              Positioned(
                top: -80.h,
                left: -60.w,
                child: Container(
                  width: 280.w,
                  height: 280.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.primaryPurple.withValues(alpha: 0.10),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _Header(step: step),
                    UIHelper.verticalSpace(24.h),
                    _StepProgress(currentStep: step),
                    UIHelper.verticalSpace(32.h),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _StepTitle(
                        key: ValueKey(step),
                        title: _stepTitles[titleIndex],
                        subtitle: _stepSubtitles[titleIndex],
                      ),
                    ),
                    UIHelper.verticalSpace(28.h),
                    PasscodeDotRow(
                      filledCount: state.enteredPin.length,
                      error: state.error,
                    ),
                    UIHelper.verticalSpace(32.h),
                    if (step == 2) _BiometricToggle(enabled: state.biometricsEnabled),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: PasscodeKeypad(
                        onDigit: (d) => context.read<ChangePasscodeBloc>().add(EnterDigitEvent(d)),
                        onDelete: () => context.read<ChangePasscodeBloc>().add(const DeleteDigitEvent()),
                        showBiometric: step == 1 && isBioEnabled,
                        onBiometric: _authenticateWithBiometrics,
                      ),
                    ),
                    UIHelper.verticalSpace(32.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int step;
  const _Header({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16.sp),
            ),
          ),
          UIHelper.horizontalSpace(16.w),
          Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: AppColors.primaryPurple, size: 20.sp),
              UIHelper.horizontalSpace(8.w),
              Text(
                'Change Vault PIN',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  final int currentStep;
  const _StepProgress({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: List.generate(3, (i) {
          final active = i < currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 6.w : 0),
              height: 3.h,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primaryPurple
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepTitle({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        UIHelper.verticalSpace(4.h),
        Text(
          subtitle,
          style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12.sp),
        ),
      ],
    );
  }
}

class _BiometricToggle extends StatelessWidget {
  final bool enabled;
  const _BiometricToggle({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(Icons.fingerprint_rounded, color: AppColors.primaryPink, size: 24.sp),
            UIHelper.horizontalSpace(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biometric Unlock',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Use Face ID or fingerprint to unlock',
                    style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 10.sp),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: (val) => context.read<ChangePasscodeBloc>().add(ToggleBiometricEvent(val)),
              activeThumbColor: AppColors.primaryPink,
              activeTrackColor: AppColors.primaryPink.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
