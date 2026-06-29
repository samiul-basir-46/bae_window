import 'package:flutter/foundation.dart';

@immutable
abstract class ChangePasswordState {
  const ChangePasswordState();
}

class ChangePasswordInitial extends ChangePasswordState {
  const ChangePasswordInitial();
}

class ChangePasswordLoading extends ChangePasswordState {
  const ChangePasswordLoading();
}

class ChangePasswordSuccess extends ChangePasswordState {
  const ChangePasswordSuccess();
}

class ChangePasswordFailure extends ChangePasswordState {
  final String? oldPasswordError;
  final String? newPasswordError;
  final String? confirmPasswordError;
  final String? generalError;

  const ChangePasswordFailure({
    this.oldPasswordError,
    this.newPasswordError,
    this.confirmPasswordError,
    this.generalError,
  });
}
