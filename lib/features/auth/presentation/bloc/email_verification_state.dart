import 'package:flutter/foundation.dart';

@immutable
abstract class EmailVerificationState {
  const EmailVerificationState();
}

class EmailVerificationInitial extends EmailVerificationState {
  const EmailVerificationInitial();
}

class EmailVerificationSending extends EmailVerificationState {
  const EmailVerificationSending();
}

class EmailVerificationSent extends EmailVerificationState {
  const EmailVerificationSent();
}

class EmailVerificationVerifying extends EmailVerificationState {
  const EmailVerificationVerifying();
}

class EmailVerificationVerified extends EmailVerificationState {
  const EmailVerificationVerified();
}

class EmailVerificationFailed extends EmailVerificationState {
  final String errorMessage;
  const EmailVerificationFailed(this.errorMessage);
}

class EmailVerificationCooldown extends EmailVerificationState {
  final int secondsRemaining;
  const EmailVerificationCooldown(this.secondsRemaining);
}
