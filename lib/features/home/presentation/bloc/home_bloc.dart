import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeInitial()) {
    on<LoadHomeDataEvent>((event, emit) {
      emit(const HomeLoading());
      emit(HomeLoaded(
        userAvatarUrl:
            "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200",
        partnerAvatarUrl:
            "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&q=80&w=200",
        partnerName: "Bae 2",
        isPartnerOnline: true,
        daysTogether: 524,
        userMoodEmoji: "😊",
        userMoodText: "Happy",
        livePeekImageUrl:
            "https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&q=80&w=500",
        awarenessMessage: "Bae is currently listening to Spotify 🎵",
        awarenessIcon: "🎧",
        relationshipPulse: const [
          PulseData(day: "M", userCount: 4, partnerCount: 6),
          PulseData(day: "T", userCount: 6, partnerCount: 4),
          PulseData(day: "W", userCount: 3, partnerCount: 5),
          PulseData(day: "T", userCount: 7, partnerCount: 5),
          PulseData(day: "F", userCount: 5, partnerCount: 8),
          PulseData(day: "S", userCount: 8, partnerCount: 4),
          PulseData(day: "S", userCount: 4, partnerCount: 7),
        ],
        questionOfTheDay: const TriviaQuestion(
          questionText: "আমাদের প্রথম ডেটের কোন মুহূর্তটি তোমার সবচেয়ে প্রিয়?",
          isAnswered: false,
        ),
        checkInLogs: const [
          CheckInLog(
              user: "You", time: "Today, 9:30 AM", mood: "Happy", emoji: "😊"),
          CheckInLog(
              user: "Bae", time: "Today, 8:15 AM", mood: "Sleepy", emoji: "😴"),
          CheckInLog(
              user: "You",
              time: "Yesterday, 10:00 PM",
              mood: "Calm",
              emoji: "😌"),
        ],
        nextSpecialDay: SpecialDay(
          title: "1.5 Year Anniversary",
          targetDate: DateTime.now()
              .add(const Duration(days: 47, hours: 12, minutes: 30)),
        ),
      ));
    });

    on<UpdateUserMoodEvent>((event, emit) {
      if (state is HomeLoaded) {
        final loadedState = state as HomeLoaded;
        emit(loadedState.copyWith(
          userMoodEmoji: event.emoji,
          userMoodText: event.text,
        ));
      }
    });

    on<UpdateAwarenessEvent>((event, emit) {
      if (state is HomeLoaded) {
        final loadedState = state as HomeLoaded;
        emit(loadedState.copyWith(
          awarenessMessage: event.message,
          awarenessIcon: event.icon,
        ));
      }
    });
  }
}
