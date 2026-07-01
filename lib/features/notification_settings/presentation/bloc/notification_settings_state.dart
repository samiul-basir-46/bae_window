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

  factory NotificationSettingsState.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsState(
      newSnap: map['newSnap'] as bool? ?? true,
      drawingNote: map['drawingNote'] as bool? ?? true,
      thinkingPulse: map['thinkingPulse'] as bool? ?? true,
      voiceFragment: map['voiceFragment'] as bool? ?? true,
      taskCompleted: map['taskCompleted'] as bool? ?? true,
      moodCheckIn: map['moodCheckIn'] as bool? ?? false,
      milestoneReminders: map['milestoneReminders'] as bool? ?? true,
      quietHoursEnabled: map['quietHoursEnabled'] as bool? ?? true,
      quietHoursStart: map['quietHoursStart'] as String? ?? '11:00 PM',
      quietHoursEnd: map['quietHoursEnd'] as String? ?? '07:00 AM',
    );
  }

  Map<String, dynamic> toMap() => {
        'newSnap': newSnap,
        'drawingNote': drawingNote,
        'thinkingPulse': thinkingPulse,
        'voiceFragment': voiceFragment,
        'taskCompleted': taskCompleted,
        'moodCheckIn': moodCheckIn,
        'milestoneReminders': milestoneReminders,
        'quietHoursEnabled': quietHoursEnabled,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
      };

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
