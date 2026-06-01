import 'package:flutter/foundation.dart';

@immutable
abstract class SplashEvent {
  const SplashEvent();
}

class CheckAuthStatusEvent extends SplashEvent {
  const CheckAuthStatusEvent();
}
