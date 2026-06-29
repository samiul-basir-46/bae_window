import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

import '../bloc/nest_bloc.dart';
import '../bloc/nest_event.dart';
import '../bloc/nest_state.dart';
import '../widgets/connection_card.dart';
import '../widgets/theme_selector.dart';
import '../widgets/settings_group.dart';
import 'package:bea_window_app/helpers/all_routes.dart';

class NestScreen extends StatelessWidget {
  const NestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NestBloc()..add(const LoadNestEvent()),
      child: Scaffold(
        backgroundColor: AppColors.softBlack,
        body: Stack(
          children: [
            // Background glow highlights
            Positioned(
              top: -50.h,
              right: -50.w,
              child: Container(
                width: 250.w,
                height: 250.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryPink.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100.h,
              left: -50.w,
              child: Container(
                width: 300.w,
                height: 300.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryPurple.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: BlocBuilder<NestBloc, NestState>(
                builder: (context, state) {
                  if (state is NestLoading || state is NestInitial) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryPurple),
                      ),
                    );
                  }

                  if (state is NestLoaded) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Nest",
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          UIHelper.verticalSpace(4.h),
                          Text(
                            "Settings for your private space",
                            style: GoogleFonts.dmSans(
                              color: Colors.white38,
                              fontSize: 12.sp,
                            ),
                          ),
                          UIHelper.verticalSpace(24.h),

                          // Connection Card
                          ConnectionCard(
                            partnerName: state.partnerName,
                            isLeftAvatarOnTop: state.isLeftAvatarOnTop,
                            onTap: () {
                              Navigator.pushNamed(context, Routes.myProfileScreen);
                            },
                          ),
                          UIHelper.verticalSpace(28.h),

                          // Security & Privacy
                          _buildSectionHeader("SECURITY & PRIVACY"),
                          SettingsGroup(
                            children: [
                              SettingsSwitchTile(
                                icon: Icons.lock_open_rounded,
                                iconColor: Colors.amber,
                                title: "Vault Lock",
                                subtitle: "Face ID / Fingerprint required",
                                value: state.isVaultLocked,
                                onChanged: (val) => context
                                    .read<NestBloc>()
                                    .add(ToggleVaultLockEvent(val)),
                              ),
                              const SettingsDivider(),
                              SettingsSwitchTile(
                                icon: Icons.self_improvement_rounded,
                                iconColor: Colors.orangeAccent,
                                title: "Focus Mode",
                                subtitle: "Silence distractions together",
                                value: state.isFocusMode,
                                onChanged: (val) => context
                                    .read<NestBloc>()
                                    .add(ToggleFocusModeEvent(val)),
                              ),
                              const SettingsDivider(),
                              SettingsMenuTile(
                                icon: Icons.key_rounded,
                                iconColor: AppColors.primaryPurple,
                                title: "Change Vault Passcode",
                                subtitle: "Update your vault lock PIN",
                                onTap: () => _showSnackbar(
                                    context, "Change Passcode triggered"),
                              ),
                              const SettingsDivider(),
                              SettingsMenuTile(
                                icon: Icons.shield_rounded,
                                iconColor: Colors.blueAccent,
                                title: "Change Password",
                                subtitle: "Update account sign-in password",
                                onTap: () => _showSnackbar(
                                    context, "Change Password triggered"),
                              ),
                            ],
                          ),
                          UIHelper.verticalSpace(24.h),

                          // Notifications
                          _buildSectionHeader("NOTIFICATIONS"),
                          SettingsGroup(
                            children: [
                              SettingsMenuTile(
                                icon: Icons.notifications_none_rounded,
                                iconColor: Colors.yellow,
                                title: "Notification Settings",
                                subtitle: "Snap, Pulse, Tasks, Quiet Hours",
                                onTap: () => _showSnackbar(
                                    context, "Notification settings tapped"),
                              ),
                            ],
                          ),
                          UIHelper.verticalSpace(24.h),

                          // Display theme selector
                          _buildSectionHeader("DISPLAY"),
                          ThemeSelector(
                            selectedTheme: state.selectedTheme,
                            onThemeChanged: (theme) => context
                                .read<NestBloc>()
                                .add(ChangeThemeEvent(theme)),
                          ),
                          UIHelper.verticalSpace(24.h),

                          // Data & Privacy
                          _buildSectionHeader("DATA & PRIVACY"),
                          SettingsGroup(
                            children: [
                              SettingsMenuTile(
                                icon: Icons.inbox_rounded,
                                iconColor: Colors.brown,
                                title: "Export My Memories",
                                subtitle: "Download photos & timeline",
                                onTap: () {
                                  Navigator.pushNamed(context, Routes.exportMemoriesScreen);
                                },
                              ),
                            ],
                          ),
                          UIHelper.verticalSpace(24.h),

                          // Account Actions
                          _buildSectionHeader("ACCOUNT"),
                          SettingsGroup(
                            children: [
                              SettingsMenuTile(
                                icon: Icons.logout_rounded,
                                iconColor: Colors.redAccent,
                                title: "Log Out",
                                subtitle:
                                    "Sign out of your account on this device",
                                textColor: Colors.redAccent,
                                onTap: () =>
                                    _showSnackbar(context, "Log Out tapped"),
                              ),
                            ],
                          ),

                          UIHelper.verticalSpace(120.h),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Text(
        title,
        style: GoogleFonts.dmSans(
          color: Colors.white38,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showSnackbar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primaryPink,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }
}
