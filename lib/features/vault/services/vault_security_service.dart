import 'biometric_service.dart';
import 'passcode_service.dart';

class VaultSecurityService {
  final BiometricService biometric = BiometricService();
  final PasscodeService passcode = PasscodeService();

  Future<bool> isSetupRequired() async {
    return !passcode.isPasscodeSet();
  }
}
