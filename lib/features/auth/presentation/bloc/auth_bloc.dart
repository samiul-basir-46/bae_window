import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  AuthBloc() : super(AuthInitial()) {
    on<GoogleSignInRequestedEvent>(_onGoogleSignInRequested);
    on<AppleSignInRequestedEvent>(_onAppleSignInRequested);
    on<ForgotPasswordRequestedEvent>(_onForgotPasswordRequested);
    on<SignUpRequestedEvent>(_onSignUpRequested);
    on<LoginRequestedEvent>(_onLoginRequested);
    on<CheckEmailVerificationRequested>(_onCheckEmailVerificationRequested);
    on<ResendVerificationEmailRequested>(_onResendVerificationEmailRequested);
  }

  Future<void> _onSignUpRequested(
    SignUpRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(SignUpLoading());
    try {
      dev.log(
          'Creating user in Firebase Auth. Email: ${event.email}, Name: ${event.name}',
          name: 'AuthBloc');
      final credential = await _authService.signUpWithEmailAndPassword(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      if (credential.user != null) {
        try {
          dev.log(
              'Firebase user created successfully (UID: ${credential.user!.uid}). Sending verification email...',
              name: 'AuthBloc');
          await _authService
              .sendEmailVerification()
              .timeout(const Duration(seconds: 3));
          dev.log('Verification email sent to: ${event.email}',
              name: 'AuthBloc');
        } catch (emailErr) {
          dev.log(
              'Failed to send verification email: $emailErr. Continuing signup.',
              name: 'AuthBloc');
        }

        dev.log('Triggering profile save to Firestore in background...',
            name: 'AuthBloc');
        _authService
            .saveUserProfile(
          uid: credential.user!.uid,
          name: event.name,
          email: event.email,
        )
            .then((_) {
          dev.log('Profile saved to Firestore in background.',
              name: 'AuthBloc');
        }).catchError((err) {
          dev.log('Firestore write failed in background: $err',
              name: 'AuthBloc');
        });
      }
      emit(SignUpSuccess());
    } on FirebaseAuthException catch (e, stack) {
      dev.log('FirebaseAuthException during signup: [${e.code}] ${e.message}',
          error: e, stackTrace: stack, name: 'AuthBloc');
      emit(SignUpFailure(e.message ?? 'An error occurred during signup.'));
    } catch (e, stack) {
      dev.log('Exception during signup: $e',
          error: e, stackTrace: stack, name: 'AuthBloc');
      emit(SignUpFailure(e.toString()));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      dev.log('Logging in user: ${event.email}', name: 'AuthBloc');
      final credential = await _authService.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      if (credential.user != null) {
        if (!credential.user!.emailVerified) {
          dev.log('User logged in but email is not verified.',
              name: 'AuthBloc');
          await _authService.sendEmailVerification();
          emit(EmailVerificationPending());
          return;
        }
      }
      dev.log('Login successful and email verified.', name: 'AuthBloc');
      emit(AuthSuccess());
    } on FirebaseAuthException catch (e, stack) {
      dev.log('FirebaseAuthException during login: [${e.code}] ${e.message}',
          error: e, stackTrace: stack, name: 'AuthBloc');
      emit(AuthFailure(e.message ?? 'An error occurred during login.'));
    } catch (e, stack) {
      dev.log('Exception during login: $e',
          error: e, stackTrace: stack, name: 'AuthBloc');
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onCheckEmailVerificationRequested(
    CheckEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      dev.log('Reloading user to check email verification status...',
          name: 'AuthBloc');
      await _authService.reloadUser();
      final isVerified = _authService.isEmailVerified();
      if (isVerified) {
        dev.log('Email verified successfully!', name: 'AuthBloc');
        emit(EmailVerificationSuccess());
      } else {
        dev.log('Email is still not verified.', name: 'AuthBloc');
        emit(EmailVerificationFailure(
            'Your email is not verified yet. Please check your inbox and click the verification link.'));
      }
    } on FirebaseAuthException catch (e, stack) {
      dev.log(
          'FirebaseAuthException during email check: [${e.code}] ${e.message}',
          error: e,
          stackTrace: stack,
          name: 'AuthBloc');
      emit(EmailVerificationFailure(e.message ??
          'An error occurred while checking verification status.'));
    } catch (e, stack) {
      dev.log('Exception during email check: $e',
          error: e, stackTrace: stack, name: 'AuthBloc');
      emit(EmailVerificationFailure(e.toString()));
    }
  }

  Future<void> _onResendVerificationEmailRequested(
    ResendVerificationEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      dev.log('Resending verification email...', name: 'AuthBloc');
      await _authService.sendEmailVerification();
      dev.log('Verification email resent successfully.', name: 'AuthBloc');
      emit(EmailVerificationPending());
    } on FirebaseAuthException catch (e, stack) {
      dev.log(
          'FirebaseAuthException during resending verification email: [${e.code}] ${e.message}',
          error: e,
          stackTrace: stack,
          name: 'AuthBloc');
      if (e.code == 'too-many-requests') {
        emit(EmailVerificationFailure(
            'Too many requests. Please wait a moment before trying again.'));
      } else {
        emit(EmailVerificationFailure(
            e.message ?? 'Failed to resend verification email.'));
      }
    } catch (e, stack) {
      dev.log('Exception during resending verification email: $e',
          error: e, stackTrace: stack, name: 'AuthBloc');
      emit(EmailVerificationFailure(e.toString()));
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
