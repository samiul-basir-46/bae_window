import 'package:flutter/foundation.dart';
import '../models/bucket_list_model.dart';

@immutable
abstract class SpaceScreenState {
  const SpaceScreenState();
}

class SpaceScreenInitial extends SpaceScreenState {
  const SpaceScreenInitial();
}

class SpaceScreenLoading extends SpaceScreenState {
  const SpaceScreenLoading();
}

class SpaceScreenLoaded extends SpaceScreenState {
  final List<BucketListItem> bucketList;
  final DateTime? anniversaryDate;
  final String partnerNickname;
  final bool isPartnerOnline;
  final String coupleId;
  final String partnerUid;
  final List<SpaceMomentItem> recentMoments;
  final double taskProgress;
  final String nextTaskTitle;

  const SpaceScreenLoaded({
    required this.bucketList,
    required this.anniversaryDate,
    required this.partnerNickname,
    required this.isPartnerOnline,
    required this.coupleId,
    required this.partnerUid,
    required this.recentMoments,
    required this.taskProgress,
    required this.nextTaskTitle,
  });

  int get anniversaryDaysLeft {
    if (anniversaryDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var target = DateTime(today.year, anniversaryDate!.month, anniversaryDate!.day);
    if (target.isBefore(today)) {
      target = DateTime(today.year + 1, anniversaryDate!.month, anniversaryDate!.day);
    }
    return target.difference(today).inDays;
  }

  SpaceScreenLoaded copyWith({
    List<BucketListItem>? bucketList,
    DateTime? anniversaryDate,
    String? partnerNickname,
    bool? isPartnerOnline,
    String? coupleId,
    String? partnerUid,
    List<SpaceMomentItem>? recentMoments,
    double? taskProgress,
    String? nextTaskTitle,
  }) {
    return SpaceScreenLoaded(
      bucketList: bucketList ?? this.bucketList,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      partnerNickname: partnerNickname ?? this.partnerNickname,
      isPartnerOnline: isPartnerOnline ?? this.isPartnerOnline,
      coupleId: coupleId ?? this.coupleId,
      partnerUid: partnerUid ?? this.partnerUid,
      recentMoments: recentMoments ?? this.recentMoments,
      taskProgress: taskProgress ?? this.taskProgress,
      nextTaskTitle: nextTaskTitle ?? this.nextTaskTitle,
    );
  }
}

class SpaceScreenError extends SpaceScreenState {
  final String message;
  const SpaceScreenError(this.message);
}

class SpaceMomentItem {
  final String user;
  final String action;
  final String time;
  final String type; // 'vault', 'task', 'note'

  const SpaceMomentItem({
    required this.user,
    required this.action,
    required this.time,
    required this.type,
  });
}
