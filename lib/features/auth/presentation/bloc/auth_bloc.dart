import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc responsible for managing authentication state.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<GoogleSignInRequestedEvent>(_onGoogleSignInRequested);
  }

  /// Handles the [GoogleSignInRequestedEvent].
  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    // 1. Emit Loading state to show the CircularProgressIndicator
    emit(AuthLoading());

    try {
      // 2. Mocking a 2-second delay to simulate Google Sign-In pop-up workflow
      await Future.delayed(const Duration(seconds: 2));

      // 3. Emit Success state to trigger navigation
      emit(AuthSuccess());
    } catch (e) {
      // 4. Emit Failure state if something goes wrong
      emit(AuthFailure(e.toString()));
    }
  }
}
