import 'package:flutter/foundation.dart';

@immutable
abstract class SplashEvent {
  const SplashEvent();
}

/// Event triggered when the Splash Screen initializes to check auth/linking status.
class CheckAuthStatusEvent extends SplashEvent {
  const CheckAuthStatusEvent();
}
