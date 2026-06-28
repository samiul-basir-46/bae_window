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
