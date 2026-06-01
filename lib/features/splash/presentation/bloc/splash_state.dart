import 'package:flutter/foundation.dart';

@immutable
abstract class SplashState {
  const SplashState();
}

class SplashInitial extends SplashState {
  const SplashInitial();
}

class SplashLoading extends SplashState {
  const SplashLoading();
}

class AuthenticatedState extends SplashState {
  const AuthenticatedState();
}

class UnauthenticatedState extends SplashState {
  const UnauthenticatedState();
}
