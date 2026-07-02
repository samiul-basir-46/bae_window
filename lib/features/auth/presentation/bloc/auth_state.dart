part of 'auth_bloc.dart';

abstract class AuthState {}

/// Initial state of the authentication flow.
class AuthInitial extends AuthState {}

/// State emitted while the authentication process is in progress.
class AuthLoading extends AuthState {}

/// State emitted upon successful authentication.
class AuthSuccess extends AuthState {}

/// State emitted when authentication fails.
class AuthFailure extends AuthState {
  final String errorMessage;

  AuthFailure(this.errorMessage);
}

class ForgotPasswordLoading extends AuthState {}

class ForgotPasswordSuccess extends AuthState {}

class ForgotPasswordFailure extends AuthState {
  final String errorMessage;

  ForgotPasswordFailure(this.errorMessage);
}

class SignUpLoading extends AuthState {}

class SignUpSuccess extends AuthState {}

class SignUpFailure extends AuthState {
  final String errorMessage;

  SignUpFailure(this.errorMessage);
}

class EmailVerificationPending extends AuthState {}

class EmailVerificationSuccess extends AuthState {}

class EmailVerificationFailure extends AuthState {
  final String errorMessage;

  EmailVerificationFailure(this.errorMessage);
}

class ProfileSetupPendingState extends AuthState {}

class PairingPendingState extends AuthState {}

class ProfileSetupLoading extends AuthState {}

class ProfileSetupSuccess extends AuthState {}

class ProfileSetupFailure extends AuthState {
  final String errorMessage;
  ProfileSetupFailure(this.errorMessage);
}

class PairingCodeGenerated extends AuthState {
  final String code;
  PairingCodeGenerated(this.code);
}

class PairingInProgress extends AuthState {}

class PairingSuccess extends AuthState {}

class PairingFailure extends AuthState {
  final String errorMessage;
  PairingFailure(this.errorMessage);
}

class PairingSkipped extends AuthState {}
