import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<GoogleSignInRequestedEvent>(_onGoogleSignInRequested);
    on<AppleSignInRequestedEvent>(_onAppleSignInRequested);
    on<ForgotPasswordRequestedEvent>(_onForgotPasswordRequested);
    on<VerifyOtpRequestedEvent>(_onVerifyOtpRequested);
    on<SignUpRequestedEvent>(_onSignUpRequested);
  }

  Future<void> _onSignUpRequested(
    SignUpRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(SignUpLoading());
    try {
      await Future.delayed(const Duration(seconds: 2));
      emit(SignUpSuccess());
    } catch (e) {
      emit(SignUpFailure(e.toString()));
    }
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(VerifyOtpLoading());
    try {
      await Future.delayed(const Duration(seconds: 2));
      emit(VerifyOtpSuccess());
    } catch (e) {
      emit(VerifyOtpFailure(e.toString()));
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(ForgotPasswordLoading());
    try {
      await Future.delayed(const Duration(seconds: 2));
      emit(ForgotPasswordSuccess());
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString()));
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(seconds: 2));
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAppleSignInRequested(
    AppleSignInRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(seconds: 2));
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}