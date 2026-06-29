import 'package:flutter/foundation.dart';

@immutable
abstract class ChangePasswordEvent {
  const ChangePasswordEvent();
}

class SubmitChangePasswordEvent extends ChangePasswordEvent {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  const SubmitChangePasswordEvent({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });
}
