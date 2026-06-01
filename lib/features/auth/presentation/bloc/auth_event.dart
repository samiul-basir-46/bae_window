part of 'auth_bloc.dart';

abstract class AuthEvent {}

/// Event triggered when the user requests to sign in or sign up with Google.
class GoogleSignInRequestedEvent extends AuthEvent {}
