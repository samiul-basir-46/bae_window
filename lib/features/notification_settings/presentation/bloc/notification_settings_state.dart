import 'package:flutter/foundation.dart';

@immutable
class NotificationSettingsState {
  // Partner Activity
  final bool newSnap;
  final bool drawingNote;
  final bool thinkingPulse;
  final bool voiceFragment;

  // Updates
  final bool taskCompleted;
  final bool moodCheckIn;
  final bool milestoneReminders;

  // Quiet Hours
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  const NotificationSettingsState({
    this.newSnap = true,
    this.drawingNote = true,
    this.thinkingPulse = true,
    this.voiceFragment = true,
    this.taskCompleted = true,
    this.moodCheckIn = false,
    this.milestoneReminders = true,
    this.quietHoursEnabled = true,
    this.quietHoursStart = "11:00 PM",
    this.quietHoursEnd = "07:00 AM",
  });

  NotificationSettingsState copyWith({
    bool? newSnap,
    bool? drawingNote,
    bool? thinkingPulse,
    bool? voiceFragment,
    bool? taskCompleted,
    bool? moodCheckIn,
    bool? milestoneReminders,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationSettingsState(
      newSnap: newSnap ?? this.newSnap,
      drawingNote: drawingNote ?? this.drawingNote,
      thinkingPulse: thinkingPulse ?? this.thinkingPulse,
      voiceFragment: voiceFragment ?? this.voiceFragment,
      taskCompleted: taskCompleted ?? this.taskCompleted,
      moodCheckIn: moodCheckIn ?? this.moodCheckIn,
      milestoneReminders: milestoneReminders ?? this.milestoneReminders,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}
