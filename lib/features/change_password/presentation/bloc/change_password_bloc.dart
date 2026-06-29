import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bea_window_app/constants/validator.dart';
import 'change_password_event.dart';
import 'change_password_state.dart';

class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  // Mock current password and historical passwords
  String _currentPassword = "password123";
  final List<String> _passwordHistory = ["previousPass1", "previousPass2"];

  ChangePasswordBloc() : super(const ChangePasswordInitial()) {
    on<SubmitChangePasswordEvent>(_onSubmitChangePassword);
  }

  Future<void> _onSubmitChangePassword(
    SubmitChangePasswordEvent event,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(const ChangePasswordLoading());

    // Artificial delay to simulate network call
    await Future.delayed(const Duration(milliseconds: 500));

    final oldPw = event.oldPassword;
    final newPw = event.newPassword;
    final confirmPw = event.confirmPassword;

    // Run validators from validator.dart
    final oldPwErr = passwordValidator(oldPw);
    final newPwErr = passwordValidator(newPw);
    final confirmPwErr = confirmPasswordValidator(confirmPw, newPw);

    if (oldPwErr != null || newPwErr != null || confirmPwErr != null) {
      emit(ChangePasswordFailure(
        oldPasswordError: oldPwErr,
        newPasswordError: newPwErr,
        confirmPasswordError: confirmPwErr,
      ));
      return;
    }

    // Verify correct old password
    if (oldPw != _currentPassword) {
      emit(const ChangePasswordFailure(
        oldPasswordError: "Incorrect old password",
      ));
      return;
    }

    // Verify new password is not same as old password
    if (newPw == _currentPassword) {
      emit(const ChangePasswordFailure(
        newPasswordError: "New password cannot be the same as your old password",
      ));
      return;
    }

    // Strict reuse verification against password history
    if (_passwordHistory.contains(newPw)) {
      emit(const ChangePasswordFailure(
        newPasswordError: "For security, you cannot reuse any of your previously used passwords",
      ));
      return;
    }

    // Success: update password history and current active password
    _passwordHistory.add(_currentPassword);
    _currentPassword = newPw;

    emit(const ChangePasswordSuccess());
  }
}
