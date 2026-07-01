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
  final bool isPaired;

  // User's own data
  final String userAvatarUrl;
  final String userMoodEmoji;
  final String userMoodText;
  final String userName;

  final String? partnerAvatarUrl;
  final String? partnerName;
  final bool? isPartnerOnline;
  final int? daysTogether;
  final String? partnerMoodEmoji;
  final String? partnerMoodText;

  final String? inviteCode;

  final String livePeekImageUrl;
  final String livePeekDrawingUrl;
  final String livePeekVoiceUrl;
  final String? latestSnapType;
  final String? awarenessMessage;
  final String? awarenessIcon;
  final List<PulseData> relationshipPulse;
  final TriviaQuestion? questionOfTheDay;
  final List<CheckInLog> checkInLogs;
  final SpecialDay? nextSpecialDay;
  final String? coupleId;

  const HomeLoaded({
    required this.isPaired,
    required this.userAvatarUrl,
    required this.userMoodEmoji,
    required this.userMoodText,
    required this.userName,
    this.partnerAvatarUrl,
    this.partnerName,
    this.isPartnerOnline,
    this.daysTogether,
    this.partnerMoodEmoji,
    this.partnerMoodText,
    this.inviteCode,
    this.livePeekImageUrl = '',
    this.livePeekDrawingUrl = '',
    this.livePeekVoiceUrl = '',
    this.latestSnapType,
    this.awarenessMessage,
    this.awarenessIcon,
    this.relationshipPulse = const [],
    this.questionOfTheDay,
    this.checkInLogs = const [],
    this.nextSpecialDay,
    this.coupleId,
  });

  HomeLoaded copyWith({
    bool? isPaired,
    String? userAvatarUrl,
    String? userMoodEmoji,
    String? userMoodText,
    String? userName,
    String? partnerAvatarUrl,
    String? partnerName,
    bool? isPartnerOnline,
    int? daysTogether,
    String? partnerMoodEmoji,
    String? partnerMoodText,
    String? inviteCode,
    String? livePeekImageUrl,
    String? livePeekDrawingUrl,
    String? livePeekVoiceUrl,
    String? latestSnapType,
    String? awarenessMessage,
    String? awarenessIcon,
    List<PulseData>? relationshipPulse,
    TriviaQuestion? questionOfTheDay,
    List<CheckInLog>? checkInLogs,
    SpecialDay? nextSpecialDay,
    String? coupleId,
  }) {
    return HomeLoaded(
      isPaired: isPaired ?? this.isPaired,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      userMoodEmoji: userMoodEmoji ?? this.userMoodEmoji,
      userMoodText: userMoodText ?? this.userMoodText,
      userName: userName ?? this.userName,
      partnerAvatarUrl: partnerAvatarUrl ?? this.partnerAvatarUrl,
      partnerName: partnerName ?? this.partnerName,
      isPartnerOnline: isPartnerOnline ?? this.isPartnerOnline,
      daysTogether: daysTogether ?? this.daysTogether,
      partnerMoodEmoji: partnerMoodEmoji ?? this.partnerMoodEmoji,
      partnerMoodText: partnerMoodText ?? this.partnerMoodText,
      inviteCode: inviteCode ?? this.inviteCode,
      livePeekImageUrl: livePeekImageUrl ?? this.livePeekImageUrl,
      livePeekDrawingUrl: livePeekDrawingUrl ?? this.livePeekDrawingUrl,
      livePeekVoiceUrl: livePeekVoiceUrl ?? this.livePeekVoiceUrl,
      latestSnapType: latestSnapType ?? this.latestSnapType,
      awarenessMessage: awarenessMessage ?? this.awarenessMessage,
      awarenessIcon: awarenessIcon ?? this.awarenessIcon,
      relationshipPulse: relationshipPulse ?? this.relationshipPulse,
      questionOfTheDay: questionOfTheDay ?? this.questionOfTheDay,
      checkInLogs: checkInLogs ?? this.checkInLogs,
      nextSpecialDay: nextSpecialDay ?? this.nextSpecialDay,
      coupleId: coupleId ?? this.coupleId,
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
