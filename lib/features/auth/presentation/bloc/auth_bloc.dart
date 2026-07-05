import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';
import 'package:bea_window_app/features/auth/services/cloudinary_service.dart';


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
    on<SaveProfileRequested>(_onSaveProfileRequested);
    on<GenerateInviteCodeRequested>(_onGenerateInviteCodeRequested);
    on<JoinWithCodeRequested>(_onJoinWithCodeRequested);
    on<SkipPairingRequested>(_onSkipPairingRequested);
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
        dev.log('Sending verification email...', name: 'AuthBloc');
        await _authService.sendEmailVerification();
        dev.log('Triggering profile save to Firestore...', name: 'AuthBloc');
        await _authService.saveUserProfile(
          uid: credential.user!.uid,
          name: event.name,
          email: event.email,
        );
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

        // Check if profile setup or pairing is pending
        try {
          final userDoc = await _authService.getUserProfile(
            credential.user!.uid,
            options: const GetOptions(source: Source.server),
          );
          if (userDoc != null) {
            final isProfileComplete = (userDoc['profileComplete'] as bool? ?? false) ||
                (userDoc['nickname'] as String? ?? '').isNotEmpty;
            if (!isProfileComplete) {
              dev.log('User logged in but profile is not completed.', name: 'AuthBloc');
              emit(ProfileSetupPendingState());
              return;
            }
            final pairStatus = userDoc['pairStatus'] as String? ?? 'none';
            if (pairStatus != 'paired' && pairStatus != 'unpaired') {
              dev.log('User logged in but pairing is pending.', name: 'AuthBloc');
              emit(PairingPendingState());
              return;
            }
          } else {
            dev.log('User logged in but Firestore document does not exist.', name: 'AuthBloc');
            emit(ProfileSetupPendingState());
            return;
          }
        } catch (firestoreError) {
          dev.log('Firestore unavailable during login gating check, skipping: $firestoreError', name: 'AuthBloc');
        }
      }
      dev.log('Login successful, profile complete, and paired.', name: 'AuthBloc');
      emit(AuthSuccess());
    } on FirebaseAuthException catch (e, stack) {
      dev.log('FirebaseAuthException during login: [${e.code}] ${e.message}',
          error: e, stackTrace: stack, name: 'AuthBloc');
      String errorMsg = e.message ?? 'An error occurred during login.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential' || e.code == 'user-not-found') {
        errorMsg = 'Incorrect email or password. Please try again.';
      }
      emit(AuthFailure(errorMsg));
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
      await _authService.sendPasswordResetEmail(event.email);
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

  Future<void> _onSaveProfileRequested(
    SaveProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(ProfileSetupLoading());
    try {
      dev.log('Saving profile setup: ${event.nickname}', name: 'AuthBloc');

      String avatarUrl = event.avatarUrl ?? '';

      // If a local file was picked, upload to Cloudinary
      if (event.avatarFile != null) {
        dev.log('Local avatar file detected — uploading to Cloudinary...',
            name: 'AuthBloc');
        final cloudinaryUrl =
            await CloudinaryService.uploadImage(event.avatarFile!);

        if (cloudinaryUrl == null) {
          dev.log('Cloudinary upload returned null — emitting failure.',
              name: 'AuthBloc');
          emit(ProfileSetupFailure(
            'Failed to upload profile picture. Please check your internet connection and try again.',
          ));
          return;
        }

        avatarUrl = cloudinaryUrl;
        dev.log('Cloudinary upload successful: $avatarUrl', name: 'AuthBloc');
      }

      await _authService.saveProfileSetup(
        nickname: event.nickname,
        avatarUrl: avatarUrl,
      );
      emit(ProfileSetupSuccess());
    } catch (e, stack) {
      dev.log('Error during profile setup: $e',
          error: e, stackTrace: stack, name: 'AuthBloc');
      emit(ProfileSetupFailure(e.toString()));
    }
  }


  Future<void> _onGenerateInviteCodeRequested(
    GenerateInviteCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(PairingInProgress());
    try {
      dev.log('Generating pairing invite code...', name: 'AuthBloc');
      final code = await _authService.generateInviteCode();
      emit(PairingCodeGenerated(code));
    } catch (e, stack) {
      dev.log('Error generating pairing code: $e', error: e, stackTrace: stack, name: 'AuthBloc');
      emit(PairingFailure(e.toString()));
    }
  }

  Future<void> _onJoinWithCodeRequested(
    JoinWithCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(PairingInProgress());
    try {
      dev.log('Attempting to join with partner code: ${event.code}', name: 'AuthBloc');
      await _authService.joinWithCode(event.code);
      emit(PairingSuccess());
    } catch (e, stack) {
      dev.log('Error joining with code: $e', error: e, stackTrace: stack, name: 'AuthBloc');
      emit(PairingFailure(e.toString()));
    }
  }

  Future<void> _onSkipPairingRequested(
    SkipPairingRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(PairingInProgress());
    try {
      dev.log('Skipping pairing step...', name: 'AuthBloc');
      await _authService.skipPairing();
      emit(PairingSkipped());
    } catch (e, stack) {
      dev.log('Error skipping pairing: $e', error: e, stackTrace: stack, name: 'AuthBloc');
      emit(PairingFailure(e.toString()));
    }
  }

}
