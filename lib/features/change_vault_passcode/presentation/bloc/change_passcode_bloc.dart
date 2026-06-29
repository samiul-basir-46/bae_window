import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bea_window_app/features/story/presentation/bloc/story_bloc.dart';
import 'package:bea_window_app/features/story/presentation/bloc/story_event.dart';
import 'change_passcode_event.dart';
import 'change_passcode_state.dart';

class ChangePasscodeBloc extends Bloc<ChangePasscodeEvent, ChangePasscodeState> {
  final StoryBloc storyBloc;
  final String? currentPin;

  ChangePasscodeBloc({
    required this.storyBloc,
    required this.currentPin,
    required bool initialBiometricsEnabled,
  }) : super(ChangePasscodeStep(step: 1, biometricsEnabled: initialBiometricsEnabled)) {
    on<EnterDigitEvent>(_onEnterDigit);
    on<DeleteDigitEvent>(_onDeleteDigit);
    on<ToggleBiometricEvent>(_onToggleBiometric);
    on<VerifyWithBiometricsSuccessEvent>(_onVerifyBiometricsSuccess);
  }

  void _onEnterDigit(EnterDigitEvent event, Emitter<ChangePasscodeState> emit) {
    final s = state as ChangePasscodeStep;
    if (s.enteredPin.length >= 4) return;

    final updated = s.enteredPin + event.digit;
    emit(s.copyWith(enteredPin: updated, clearError: true));

    if (updated.length == 4) {
      _handlePinComplete(updated, emit);
    }
  }

  void _onDeleteDigit(DeleteDigitEvent event, Emitter<ChangePasscodeState> emit) {
    final s = state as ChangePasscodeStep;
    if (s.enteredPin.isEmpty) return;
    emit(s.copyWith(
      enteredPin: s.enteredPin.substring(0, s.enteredPin.length - 1),
      clearError: true,
    ));
  }

  void _onToggleBiometric(ToggleBiometricEvent event, Emitter<ChangePasscodeState> emit) {
    final s = state as ChangePasscodeStep;
    emit(s.copyWith(biometricsEnabled: event.enabled));
  }

  void _onVerifyBiometricsSuccess(
    VerifyWithBiometricsSuccessEvent event,
    Emitter<ChangePasscodeState> emit,
  ) {
    final s = state as ChangePasscodeStep;
    if (s.step == 1) {
      emit(ChangePasscodeStep(
        step: 2,
        biometricsEnabled: s.biometricsEnabled,
      ));
    }
  }

  void _handlePinComplete(String pin, Emitter<ChangePasscodeState> emit) {
    final s = state as ChangePasscodeStep;

    switch (s.step) {
      case 1:
        final savedPin = currentPin ?? '1234';
        if (pin != savedPin) {
          emit(s.copyWith(enteredPin: '', error: 'Incorrect PIN. Please try again.'));
        } else {
          emit(ChangePasscodeStep(
            step: 2,
            biometricsEnabled: s.biometricsEnabled,
          ));
        }
        break;

      case 2:
        final savedPin = currentPin ?? '1234';
        if (pin == savedPin) {
          emit(s.copyWith(
            enteredPin: '',
            error: 'New PIN cannot be the same as current PIN.',
          ));
        } else {
          emit(ChangePasscodeStep(
            step: 3,
            newPin: pin,
            biometricsEnabled: s.biometricsEnabled,
          ));
        }
        break;

      case 3:
        if (pin != s.newPin) {
          emit(s.copyWith(
            enteredPin: '',
            error: 'PINs do not match. Please re-enter.',
          ));
        } else {
          storyBloc.add(SetupVaultPinEvent(
            pin: s.newPin,
            enableBiometrics: s.biometricsEnabled,
          ));
          emit(const ChangePasscodeSuccess());
        }
        break;
    }
  }
}
