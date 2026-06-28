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
