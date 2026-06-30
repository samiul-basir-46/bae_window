part of 'auth_bloc.dart';

abstract class AuthEvent {
  const AuthEvent();  // const add
}

class GoogleSignInRequestedEvent extends AuthEvent {
  const GoogleSignInRequestedEvent();
}

class AppleSignInRequestedEvent extends AuthEvent {
  const AppleSignInRequestedEvent();
}

class ForgotPasswordRequestedEvent extends AuthEvent {
  final String email;
  const ForgotPasswordRequestedEvent(this.email);
}