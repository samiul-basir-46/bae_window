import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'splash_event.dart';
import 'splash_state.dart';

/// BLoC class managing state transitions for the BaeWindow Splash Screen.
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(const SplashInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  /// Event handler for CheckAuthStatusEvent.
  /// Simulates a 3-second delay to check authentication status.
  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoading());

    // Mock a 3-second delay representing checking secure storage, GetStorage, or Firebase Auth.
    await Future.delayed(const Duration(seconds: 3));

    // Emit final state. For this mock implementation, we emit UnauthenticatedState
    // to guide the user into the onboarding/linking flow. In real production,
    // this would check against secure storage values or active Firebase Auth user session.
    emit(const UnauthenticatedState());
  }
}
