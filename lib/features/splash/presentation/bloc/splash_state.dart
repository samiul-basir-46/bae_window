import 'package:flutter/foundation.dart';

@immutable
abstract class SplashState {
  const SplashState();
}

/// Initial state before any check begins.
class SplashInitial extends SplashState {
  const SplashInitial();
}

/// State emitted while simulating the auth/linking verification check.
class SplashLoading extends SplashState {
  const SplashLoading();
}

/// State emitted if the user is authenticated and successfully linked with a partner.
class AuthenticatedState extends SplashState {
  const AuthenticatedState();
}

/// State emitted if the user is not authenticated or not linked with a partner yet.
class UnauthenticatedState extends SplashState {
  const UnauthenticatedState();
}
