import 'package:flutter/foundation.dart';

@immutable
abstract class HomeState {
  const HomeState();
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final String userAvatarUrl;
  final String partnerAvatarUrl;
  final String partnerName;
  final bool isPartnerOnline;
  final int daysTogether;
  final String userMoodEmoji;
  final String userMoodText;
  final String livePeekImageUrl;
  final String? awarenessMessage;
  final String? awarenessIcon;
  final List<PulseData> relationshipPulse;
  final TriviaQuestion? questionOfTheDay;
  final List<CheckInLog> checkInLogs;
  final SpecialDay? nextSpecialDay;

  const HomeLoaded({
    required this.userAvatarUrl,
    required this.partnerAvatarUrl,
    required this.partnerName,
    required this.isPartnerOnline,
    required this.daysTogether,
    required this.userMoodEmoji,
    required this.userMoodText,
    required this.livePeekImageUrl,
    this.awarenessMessage,
    this.awarenessIcon,
    required this.relationshipPulse,
    this.questionOfTheDay,
    required this.checkInLogs,
    this.nextSpecialDay,
  });

  HomeLoaded copyWith({
    String? userAvatarUrl,
    String? partnerAvatarUrl,
    String? partnerName,
    bool? isPartnerOnline,
    int? daysTogether,
    String? userMoodEmoji,
    String? userMoodText,
    String? livePeekImageUrl,
    String? awarenessMessage,
    String? awarenessIcon,
    List<PulseData>? relationshipPulse,
    TriviaQuestion? questionOfTheDay,
    List<CheckInLog>? checkInLogs,
    SpecialDay? nextSpecialDay,
  }) {
    return HomeLoaded(
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      partnerAvatarUrl: partnerAvatarUrl ?? this.partnerAvatarUrl,
      partnerName: partnerName ?? this.partnerName,
      isPartnerOnline: isPartnerOnline ?? this.isPartnerOnline,
      daysTogether: daysTogether ?? this.daysTogether,
      userMoodEmoji: userMoodEmoji ?? this.userMoodEmoji,
      userMoodText: userMoodText ?? this.userMoodText,
      livePeekImageUrl: livePeekImageUrl ?? this.livePeekImageUrl,
      awarenessMessage: awarenessMessage ?? this.awarenessMessage,
      awarenessIcon: awarenessIcon ?? this.awarenessIcon,
      relationshipPulse: relationshipPulse ?? this.relationshipPulse,
      questionOfTheDay: questionOfTheDay ?? this.questionOfTheDay,
      checkInLogs: checkInLogs ?? this.checkInLogs,
      nextSpecialDay: nextSpecialDay ?? this.nextSpecialDay,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
}

class PulseData {
  final String day;
  final int userCount;
  final int partnerCount;

  const PulseData({
    required this.day,
    required this.userCount,
    required this.partnerCount,
  });
}

class TriviaQuestion {
  final String questionText;
  final bool isAnswered;

  const TriviaQuestion({
    required this.questionText,
    required this.isAnswered,
  });
}

class CheckInLog {
  final String user;
  final String time;
  final String mood;
  final String emoji;

  const CheckInLog({
    required this.user,
    required this.time,
    required this.mood,
    required this.emoji,
  });
}

class SpecialDay {
  final String title;
  final DateTime targetDate;

  const SpecialDay({
    required this.title,
    required this.targetDate,
  });
}
