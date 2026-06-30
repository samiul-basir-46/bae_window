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

class VerifyOtpRequestedEvent extends AuthEvent {
  final String otp;
  const VerifyOtpRequestedEvent(this.otp);
}

class SignUpRequestedEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const SignUpRequestedEvent({
    required this.name,
    required this.email,
    required this.password,
  });
}