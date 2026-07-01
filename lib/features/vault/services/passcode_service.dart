import 'package:get_storage/get_storage.dart';

class PasscodeService {
  final GetStorage _storage = GetStorage();
  static const String _passcodeKey = 'vault_secure_passcode';

  bool isPasscodeSet() {
    final code = _storage.read<String>(_passcodeKey);
    return code != null && code.isNotEmpty;
  }

  Future<void> savePasscode(String passcode) async {
    await _storage.write(_passcodeKey, passcode);
  }

  bool verifyPasscode(String passcode) {
    final savedCode = _storage.read<String>(_passcodeKey);
    return savedCode == passcode;
  }

  Future<void> clearPasscode() async {
    await _storage.remove(_passcodeKey);
  }
}
