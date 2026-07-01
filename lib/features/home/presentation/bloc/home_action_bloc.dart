import 'package:bea_window_app/features/auth/services/cloudinary_service.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_action_event.dart';
import 'home_action_state.dart';

class HomeActionBloc extends Bloc<HomeActionEvent, HomeActionState> {
  final FirebaseAuthService _authService;

  HomeActionBloc({FirebaseAuthService? authService})
      : _authService = authService ?? FirebaseAuthService(),
        super(const HomeActionInitial()) {
    on<ShareHomeMediaRequested>(_onShareMedia);
    on<SendHomePulseRequested>(_onSendPulse);
    on<UpdateRelationshipDateRequested>(_onUpdateRelationshipDate);
  }

  Future<void> _onShareMedia(
    ShareHomeMediaRequested event,
    Emitter<HomeActionState> emit,
  ) async {
    if (state is HomeActionLoading) return;

    final label = switch (event.mediaType) {
      HomeMediaType.image => 'snap',
      HomeMediaType.drawing => 'drawing',
      HomeMediaType.voice => 'voice message',
    };
    emit(HomeActionLoading('Uploading $label to Bae...'));

    try {
      final url = event.mediaType == HomeMediaType.voice
          ? await CloudinaryService.uploadAudio(event.file)
          : await CloudinaryService.uploadImage(event.file);
      if (url == null || url.isEmpty) {
        throw Exception('Failed to upload $label. Please try again.');
      }

      final snapType = switch (event.mediaType) {
        HomeMediaType.image => 'Image',
        HomeMediaType.drawing => 'Draw',
        HomeMediaType.voice => 'Voice',
      };
      await _authService.updateLatestSnap(
        snapUrl: url,
        snapType: snapType,
      );
      emit(HomeActionSuccess('${_capitalize(label)} sent to Bae!'));
    } catch (e) {
      emit(HomeActionFailure(_cleanError(e)));
    }
  }

  Future<void> _onSendPulse(
    SendHomePulseRequested event,
    Emitter<HomeActionState> emit,
  ) async {
    if (state is HomeActionLoading) return;
    emit(const HomeActionLoading('Sending pulse to Bae...'));
    try {
      await _authService.sendPulse();
      emit(const HomeActionSuccess('Pulse sent to your Bae!'));
    } catch (e) {
      emit(HomeActionFailure(_cleanError(e)));
    }
  }

  Future<void> _onUpdateRelationshipDate(
    UpdateRelationshipDateRequested event,
    Emitter<HomeActionState> emit,
  ) async {
    if (state is HomeActionLoading) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      emit(const HomeActionFailure('No authenticated user found.'));
      return;
    }

    emit(const HomeActionLoading('Updating relationship date...'));
    try {
      await _authService.updateRelationshipStartDate(
        uid,
        event.formattedDate,
      );
      emit(const HomeActionSuccess('Relationship date updated for both.'));
    } catch (e) {
      emit(HomeActionFailure(_cleanError(e)));
    }
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
