import 'package:flutter/foundation.dart';

@immutable
abstract class OnboardingState {
  final int pageIndex;
  const OnboardingState(this.pageIndex);
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial() : super(0);
}

class OnboardingPageUpdate extends OnboardingState {
  const OnboardingPageUpdate(super.pageIndex);
}

class OnboardingFinished extends OnboardingState {
  const OnboardingFinished(super.pageIndex);
}
