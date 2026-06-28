import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeInitial()) {
    on<LoadHomeDataEvent>((event, emit) {
      emit(const HomeLoading());
      emit(const HomeLoaded(
        userAvatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200",
        partnerAvatarUrl: "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&q=80&w=200",
        partnerName: "Bae 2",
        isPartnerOnline: true,
        daysTogether: 524,
        userMoodEmoji: "😊",
        userMoodText: "Happy",
        livePeekImageUrl: "https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&q=80&w=500",
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
  }
}
