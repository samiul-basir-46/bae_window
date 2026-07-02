import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bea_window_app/constants/validator.dart';
import 'change_password_event.dart';
import 'change_password_state.dart';

class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  ChangePasswordBloc() : super(const ChangePasswordInitial()) {
    on<SubmitChangePasswordEvent>(_onSubmitChangePassword);
  }

  Future<void> _onSubmitChangePassword(
    SubmitChangePasswordEvent event,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(const ChangePasswordLoading());

    final oldPw = event.oldPassword;
    final newPw = event.newPassword;
    final confirmPw = event.confirmPassword;

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

    if (newPw == oldPw) {
      emit(const ChangePasswordFailure(
        newPasswordError: "New password cannot be the same as your old password",
      ));
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        emit(const ChangePasswordFailure(
          generalError: "No signed-in user found. Please log in again.",
        ));
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPw,
      );
      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPw);

      emit(const ChangePasswordSuccess());
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          emit(const ChangePasswordFailure(
            oldPasswordError: "Incorrect old password",
          ));
          break;
        case 'weak-password':
          emit(const ChangePasswordFailure(
            newPasswordError: "Password is too weak. Please choose a stronger one.",
          ));
          break;
        case 'requires-recent-login':
          emit(const ChangePasswordFailure(
            generalError: "Session expired. Please log out and log back in.",
          ));
          break;
        default:
          emit(ChangePasswordFailure(
            generalError: e.message ?? "Something went wrong. Please try again.",
          ));
      }
    } catch (e) {
      emit(ChangePasswordFailure(
        generalError: e.toString(),
      ));
    }
  }
}
