import 'package:flutter/foundation.dart';

@immutable
abstract class ChangePasscodeState {
  const ChangePasscodeState();
}

class ChangePasscodeStep extends ChangePasscodeState {
  final int step;
  final String enteredPin;
  final String newPin;
  final bool biometricsEnabled;
  final String? error;

  const ChangePasscodeStep({
    required this.step,
    this.enteredPin = '',
    this.newPin = '',
    this.biometricsEnabled = false,
    this.error,
  });

  ChangePasscodeStep copyWith({
    int? step,
    String? enteredPin,
    String? newPin,
    bool? biometricsEnabled,
    String? error,
    bool clearError = false,
  }) {
    return ChangePasscodeStep(
      step: step ?? this.step,
      enteredPin: enteredPin ?? this.enteredPin,
      newPin: newPin ?? this.newPin,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChangePasscodeSuccess extends ChangePasscodeState {
  const ChangePasscodeSuccess();
}
