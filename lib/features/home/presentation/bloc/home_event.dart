import 'package:flutter/foundation.dart';
import 'home_state.dart';

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

/// Internal event — fired when the shared couple document changes
class CoupleDataUpdated extends HomeEvent {
  final Map<String, dynamic> data;
  const CoupleDataUpdated(this.data);
}

class AnswerQuestionTogetherEvent extends HomeEvent {
  final String questionText;
  const AnswerQuestionTogetherEvent(this.questionText);
}

class NextSpecialDayUpdated extends HomeEvent {
  final dynamic nextSpecialDay; // Using dynamic or SpecialDay from home_state.dart
  const NextSpecialDayUpdated(this.nextSpecialDay);
}

class TriviaDataUpdated extends HomeEvent {
  final TriviaQuestion? question;
  const TriviaDataUpdated(this.question);
}

