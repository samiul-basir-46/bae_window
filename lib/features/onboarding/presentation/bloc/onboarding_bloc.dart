import 'package:flutter_bloc/flutter_bloc.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingInitial()) {
    on<PageChangedEvent>(_onPageChanged);
    on<FinishOnboardingEvent>(_onFinishOnboarding);
  }

  void _onPageChanged(PageChangedEvent event, Emitter<OnboardingState> emit) {
    emit(OnboardingPageUpdate(event.pageIndex));
  }

  void _onFinishOnboarding(FinishOnboardingEvent event, Emitter<OnboardingState> emit) {
    emit(OnboardingFinished(state.pageIndex));
  }
}
