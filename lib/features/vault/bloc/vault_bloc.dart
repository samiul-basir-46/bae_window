import 'package:flutter_bloc/flutter_bloc.dart';
import 'vault_event.dart';
import 'vault_state.dart';
import '../services/vault_security_service.dart';

class VaultBloc extends Bloc<VaultEvent, VaultState> {
  final VaultSecurityService _securityService = VaultSecurityService();

  VaultBloc() : super(const VaultInitial()) {
    on<CheckVaultStatusEvent>(_onCheckStatus);
    on<SetupVaultPasscodeEvent>(_onSetupPasscode);
    on<AuthenticateBiometricEvent>(_onAuthenticateBiometric);
    on<AuthenticatePasscodeEvent>(_onAuthenticatePasscode);
    on<LockVaultEvent>(_onLockVault);
    on<HideVaultEvent>(_onHideVault);
    on<ShowLockScreenEvent>(_onShowLockScreen);
  }

  Future<void> _onCheckStatus(CheckVaultStatusEvent event, Emitter<VaultState> emit) async {
    final setupRequired = await _securityService.isSetupRequired();
    if (setupRequired) {
      emit(const VaultSetupRequired());
    } else {
      final bioAvailable = await _securityService.biometric.isBiometricAvailable();
      emit(VaultLocked(isBiometricAvailable: bioAvailable));
    }
  }

  Future<void> _onSetupPasscode(SetupVaultPasscodeEvent event, Emitter<VaultState> emit) async {
    await _securityService.passcode.savePasscode(event.passcode);
    final bioAvailable = await _securityService.biometric.isBiometricAvailable();
    emit(VaultLocked(isBiometricAvailable: bioAvailable));
  }

  Future<void> _onAuthenticateBiometric(AuthenticateBiometricEvent event, Emitter<VaultState> emit) async {
    emit(const VaultAuthenticating());
    final success = await _securityService.biometric.authenticate();
    final bioAvailable = await _securityService.biometric.isBiometricAvailable();
    if (success) {
      emit(const VaultAuthSuccess());
    } else {
      emit(VaultLocked(
        isBiometricAvailable: bioAvailable,
        errorMessage: "Biometric authentication failed",
      ));
    }
  }

  Future<void> _onAuthenticatePasscode(AuthenticatePasscodeEvent event, Emitter<VaultState> emit) async {
    emit(const VaultAuthenticating());
    final success = _securityService.passcode.verifyPasscode(event.passcode);
    final bioAvailable = await _securityService.biometric.isBiometricAvailable();
    if (success) {
      emit(const VaultAuthSuccess());
    } else {
      emit(VaultLocked(
        isBiometricAvailable: bioAvailable,
        errorMessage: "Incorrect passcode. Please try again.",
      ));
    }
  }

  void _onLockVault(LockVaultEvent event, Emitter<VaultState> emit) {
    _securityService.biometric.isBiometricAvailable().then((bioAvailable) {
      add(const ShowLockScreenEvent());
    });
  }

  void _onHideVault(HideVaultEvent event, Emitter<VaultState> emit) {
    emit(const VaultBackgroundHidden());
  }

  Future<void> _onShowLockScreen(ShowLockScreenEvent event, Emitter<VaultState> emit) async {
    final bioAvailable = await _securityService.biometric.isBiometricAvailable();
    emit(VaultLocked(isBiometricAvailable: bioAvailable));
  }
}
