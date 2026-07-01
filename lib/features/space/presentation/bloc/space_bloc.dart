import 'dart:developer' as dev;

import 'package:bea_window_app/helpers/notification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'space_event.dart';
import 'space_state.dart';

class SpaceBloc extends Bloc<SpaceEvent, SpaceState> {
  SpaceBloc() : super(const SpaceInitial()) {
    on<LoadSpaceEvent>(_onLoadSpace);
    on<SendLoveNoteEvent>(_onSendLoveNote);
    on<TogglePartnerStatusEvent>(_onTogglePartnerStatus);
  }

  void _onLoadSpace(LoadSpaceEvent event, Emitter<SpaceState> emit) {
    emit(const SpaceLoading());

    // Initial dummy moments
    final initialMoments = [
      const MomentItem(
        user: "Rafiq",
        action: "added a photo to Vault",
        time: "5m ago",
        type: "vault",
      ),
      const MomentItem(
        user: "Babu",
        action: "completed a task: Book flight tickets",
        time: "1h ago",
        type: "task",
      ),
      const MomentItem(
        user: "Rafiq",
        action: "sent a Love Note: 'Miss you!'",
        time: "2h ago",
        type: "note",
      ),
    ];

    emit(SpaceLoaded(
      partnerName: "Babu",
      isPartnerOnline: true,
      daysTogether: 245,
      currentMood: "In Love ❤️",
      taskProgress: 0.65,
      nextTaskTitle: "Book dinner table",
      recentMoments: initialMoments,
    ));
  }

  Future<void> _onSendLoveNote(
    SendLoveNoteEvent event,
    Emitter<SpaceState> emit,
  ) async {
    final currentState = state;
    if (currentState is SpaceLoaded) {
      final updatedMoments = List<MomentItem>.from(currentState.recentMoments);
      updatedMoments.insert(
        0,
        MomentItem(
          user: "You",
          action: "sent a Love Note: '${event.note}'",
          time: "Just now",
          type: "note",
        ),
      );

      emit(currentState.copyWith(recentMoments: updatedMoments));
      try {
        await PushNotificationService.createLoveNoteEvent(event.note);
      } catch (e, stack) {
        dev.log(
          'Could not create love-note notification event',
          name: 'SpaceBloc',
          error: e,
          stackTrace: stack,
        );
      }
    }
  }

  void _onTogglePartnerStatus(
      TogglePartnerStatusEvent event, Emitter<SpaceState> emit) {
    final currentState = state;
    if (currentState is SpaceLoaded) {
      emit(currentState.copyWith(isPartnerOnline: event.isOnline));
    }
  }
}
