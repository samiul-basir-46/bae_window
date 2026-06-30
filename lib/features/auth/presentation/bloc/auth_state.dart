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

class VerifyOtpLoading extends AuthState {}

class VerifyOtpSuccess extends AuthState {}

class VerifyOtpFailure extends AuthState {
  final String errorMessage;

  VerifyOtpFailure(this.errorMessage);
}

class SignUpLoading extends AuthState {}

class SignUpSuccess extends AuthState {}

class SignUpFailure extends AuthState {
  final String errorMessage;

  SignUpFailure(this.errorMessage);
}

