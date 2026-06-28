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

  const HomeLoaded({
    required this.userAvatarUrl,
    required this.partnerAvatarUrl,
    required this.partnerName,
    required this.isPartnerOnline,
    required this.daysTogether,
    required this.userMoodEmoji,
    required this.userMoodText,
    required this.livePeekImageUrl,
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
    );
  }
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
}
