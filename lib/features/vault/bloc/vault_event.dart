import 'package:flutter/foundation.dart';

@immutable
abstract class VaultEvent {
  const VaultEvent();
}

class CheckVaultStatusEvent extends VaultEvent {
  const CheckVaultStatusEvent();
}

class AuthenticateBiometricEvent extends VaultEvent {
  const AuthenticateBiometricEvent();
}

class AuthenticatePasscodeEvent extends VaultEvent {
  final String passcode;
  const AuthenticatePasscodeEvent(this.passcode);
}

class SetupVaultPasscodeEvent extends VaultEvent {
  final String passcode;
  const SetupVaultPasscodeEvent(this.passcode);
}

class LockVaultEvent extends VaultEvent {
  const LockVaultEvent();
}

class HideVaultEvent extends VaultEvent {
  const HideVaultEvent();
}

class ShowLockScreenEvent extends VaultEvent {
  const ShowLockScreenEvent();
}
