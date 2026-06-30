import 'package:flutter/foundation.dart';

@immutable
abstract class HomeEvent {
  const HomeEvent();
}

class LoadHomeDataEvent extends HomeEvent {
  const LoadHomeDataEvent();
}

class UpdateUserMoodEvent extends HomeEvent {
  final String emoji;
  final String text;

  const UpdateUserMoodEvent({
    required this.emoji,
    required this.text,
  });
}

class UpdateAwarenessEvent extends HomeEvent {
  final String? message;
  final String? icon;

  const UpdateAwarenessEvent({
    this.message,
    this.icon,
  });
}

/// Internal event — fired by Firestore stream when user's own data changes
class UserDataUpdated extends HomeEvent {
  final Map<String, dynamic> data;
  const UserDataUpdated(this.data);
}

/// Internal event — fired by Firestore stream when partner's data changes
class PartnerDataUpdated extends HomeEvent {
  final Map<String, dynamic> data;
  const PartnerDataUpdated(this.data);
}
