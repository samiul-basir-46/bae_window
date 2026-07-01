import 'package:flutter/foundation.dart';

@immutable
abstract class VaultState {
  const VaultState();
}

class VaultInitial extends VaultState {
  const VaultInitial();
}

class VaultSetupRequired extends VaultState {
  const VaultSetupRequired();
}

class VaultLocked extends VaultState {
  final bool isBiometricAvailable;
  final String? errorMessage;

  const VaultLocked({
    required this.isBiometricAvailable,
    this.errorMessage,
  });
}

class VaultAuthenticating extends VaultState {
  const VaultAuthenticating();
}

class VaultAuthSuccess extends VaultState {
  const VaultAuthSuccess();
}

class VaultAuthFailure extends VaultState {
  final String message;
  const VaultAuthFailure(this.message);
}

class VaultBackgroundHidden extends VaultState {
  const VaultBackgroundHidden();
}
