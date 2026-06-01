import 'package:flutter/foundation.dart';

@immutable
abstract class OnboardingEvent {
  const OnboardingEvent();
}

class PageChangedEvent extends OnboardingEvent {
  final int pageIndex;
  const PageChangedEvent(this.pageIndex);
}

class FinishOnboardingEvent extends OnboardingEvent {
  const FinishOnboardingEvent();
}
