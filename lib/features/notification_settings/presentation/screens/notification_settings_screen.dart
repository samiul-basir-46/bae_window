import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

import '../bloc/notification_settings_bloc.dart';
import '../bloc/notification_settings_event.dart';
import '../bloc/notification_settings_state.dart';
import 'package:bea_window_app/common_widgets/bae_switch.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationSettingsBloc()..add(const LoadNotificationSettingsEvent()),
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlack,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100.h,
            right: -50.w,
            child: Container(
              width: 280.w,
              height: 280.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6E7F).withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
                    builder: (context, state) {
                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                        children: [
                          _buildSectionHeader("PARTNER ACTIVITY"),
                          _buildGroupContainer([
                            _buildSwitchTile(
                              context: context,
                              emoji: "📸",
                              title: "New Snap",
                              subtitle: "When Bae sends a photo",
                              value: state.newSnap,
                              storageKey: "newSnap",
                            ),
                            _buildDivider(),
                            _buildSwitchTile(
                              context: context,
                              emoji: "✏️",
                              title: "Drawing / Note",
                              subtitle: "When Bae shares a note",
                              value: state.drawingNote,
                              storageKey: "drawingNote",
                            ),
                            _buildDivider(),
                            _buildSwitchTile(
                              context: context,
                              emoji: "💖",
                              title: "Thinking of You Pulse",
                              subtitle: "Vibration + custom sound",
                              value: state.thinkingPulse,
                              storageKey: "thinkingPulse",
                            ),
                            _buildDivider(),
                            _buildSwitchTile(
                              context: context,
                              emoji: "🎙️",
                              title: "Voice Fragment",
                              subtitle: "When Bae sends a voice clip",
                              value: state.voiceFragment,
                              storageKey: "voiceFragment",
                            ),
                          ]),
                          UIHelper.verticalSpace(24.h),

                          _buildSectionHeader("UPDATES"),
                          _buildGroupContainer([
                            _buildSwitchTile(
                              context: context,
                              emoji: "✅",
                              title: "Task Completed",
                              subtitle: "When task status updates",
                              value: state.taskCompleted,
                              storageKey: "taskCompleted",
                            ),
                            _buildDivider(),
                            _buildSwitchTile(
                              context: context,
                              emoji: "😊",
                              title: "Mood Check-in",
                              subtitle: "Daily emotional updates",
                              value: state.moodCheckIn,
                              storageKey: "moodCheckIn",
                            ),
                            _buildDivider(),
                            _buildSwitchTile(
                              context: context,
                              emoji: "🎉",
                              title: "Milestone Reminders",
                              subtitle: "Upcoming anniversary alerts",
                              value: state.milestoneReminders,
                              storageKey: "milestoneReminders",
                            ),
                          ]),
                          UIHelper.verticalSpace(24.h),

                          _buildSectionHeader("QUIET HOURS"),
                          _buildGroupContainer([
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Enable Quiet Hours",
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  BaeSwitch(
                                    value: state.quietHoursEnabled,
                                    onChanged: (val) {
                                      context.read<NotificationSettingsBloc>().add(
                                            ToggleSettingEvent("quietHoursEnabled", val),
                                          );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (state.quietHoursEnabled) ...[
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                child: Row(
                                  children: [
                                    _buildTimeButton(context, state.quietHoursStart, true),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                                      child: Text(
                                        "to",
                                        style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12.sp),
                                      ),
                                    ),
                                    _buildTimeButton(context, state.quietHoursEnd, false),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                child: Text(
                                  "During Quiet Hours, everything stays silent except Pulse — so nothing urgent gets missed",
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white24,
                                    fontSize: 10.sp,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ]
                          ]),
                          UIHelper.verticalSpace(40.h),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.w),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16.sp),
            ),
          ),
          UIHelper.horizontalSpace(16.w),
          Text(
            "Notifications",
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
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

  Widget _buildGroupContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String emoji,
    required String title,
    required String subtitle,
    required bool value,
    required String storageKey,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(emoji, style: TextStyle(fontSize: 18.sp)),
          ),
          UIHelper.horizontalSpace(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  UIHelper.verticalSpace(2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      color: Colors.white24,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
          BaeSwitch(
            value: value,
            onChanged: (val) {
              context.read<NotificationSettingsBloc>().add(
                    ToggleSettingEvent(storageKey, val),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.04),
      height: 1.h,
      thickness: 1.h,
    );
  }

  Widget _buildTimeButton(BuildContext context, String time, bool isStart) {
    return GestureDetector(
      onTap: () async {
        final timeParts = time.split(" ");
        final hourMin = timeParts[0].split(":");
        var hour = int.parse(hourMin[0]);
        final minute = int.parse(hourMin[1]);
        if (timeParts[1] == "PM" && hour < 12) {
          hour += 12;
        } else if (timeParts[1] == "AM" && hour == 12) {
          hour = 0;
        }

        final selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primaryPink,
                  onPrimary: Colors.white,
                  surface: AppColors.softBlack,
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );

        if (selectedTime != null && context.mounted) {
          final formattedTime = selectedTime.format(context);
          context.read<NotificationSettingsBloc>().add(
                UpdateQuietHoursEvent(
                  start: isStart ? formattedTime : null,
                  end: isStart ? null : formattedTime,
                ),
              );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          time,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
