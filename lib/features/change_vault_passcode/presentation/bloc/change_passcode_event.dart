import 'package:flutter/foundation.dart';

@immutable
abstract class ChangePasscodeEvent {
  const ChangePasscodeEvent();
}

class EnterDigitEvent extends ChangePasscodeEvent {
  final String digit;
  const EnterDigitEvent(this.digit);
}

class DeleteDigitEvent extends ChangePasscodeEvent {
  const DeleteDigitEvent();
}

class ToggleBiometricEvent extends ChangePasscodeEvent {
  final bool enabled;
  const ToggleBiometricEvent(this.enabled);
}

class VerifyWithBiometricsSuccessEvent extends ChangePasscodeEvent {
  const VerifyWithBiometricsSuccessEvent();
}
