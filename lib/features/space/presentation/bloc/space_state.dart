import 'package:flutter/foundation.dart';

@immutable
abstract class SpaceState {
  const SpaceState();
}

class SpaceInitial extends SpaceState {
  const SpaceInitial();
}

class SpaceLoading extends SpaceState {
  const SpaceLoading();
}

class SpaceLoaded extends SpaceState {
  final String partnerName;
  final bool isPartnerOnline;
  final int daysTogether;
  final String currentMood;
  final double taskProgress;
  final String nextTaskTitle;
  final List<MomentItem> recentMoments;

  const SpaceLoaded({
    required this.partnerName,
    required this.isPartnerOnline,
    required this.daysTogether,
    required this.currentMood,
    required this.taskProgress,
    required this.nextTaskTitle,
    required this.recentMoments,
  });

  SpaceLoaded copyWith({
    String? partnerName,
    bool? isPartnerOnline,
    int? daysTogether,
    String? currentMood,
    double? taskProgress,
    String? nextTaskTitle,
    List<MomentItem>? recentMoments,
  }) {
    return SpaceLoaded(
      partnerName: partnerName ?? this.partnerName,
      isPartnerOnline: isPartnerOnline ?? this.isPartnerOnline,
      daysTogether: daysTogether ?? this.daysTogether,
      currentMood: currentMood ?? this.currentMood,
      taskProgress: taskProgress ?? this.taskProgress,
      nextTaskTitle: nextTaskTitle ?? this.nextTaskTitle,
      recentMoments: recentMoments ?? this.recentMoments,
    );
  }
}

class SpaceError extends SpaceState {
  final String message;
  const SpaceError(this.message);
}

class MomentItem {
  final String user;
  final String action;
  final String time;
  final String type; // 'vault', 'task', 'note'

  const MomentItem({
    required this.user,
    required this.action,
    required this.time,
    required this.type,
  });
}
