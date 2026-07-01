import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/email_verification_repository.dart';
import 'email_verification_state.dart';

class EmailVerificationCubit extends Cubit<EmailVerificationState> {
  final EmailVerificationRepository _repository = EmailVerificationRepository();
  Timer? _cooldownTimer;

  EmailVerificationCubit() : super(const EmailVerificationInitial());

  Future<void> sendVerificationEmail({
    required String uid,
    required String email,
    required String name,
  }) async {
    emit(const EmailVerificationSending());
    try {
      await _repository.sendVerification(uid: uid, email: email, name: name);
      emit(const EmailVerificationSent());
      _startCooldown();
    } catch (e) {
      emit(EmailVerificationFailed(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> verifyToken({
    required String uid,
    required String token,
  }) async {
    emit(const EmailVerificationVerifying());
    final success = await _repository.verifyToken(uid: uid, token: token);
    if (success) {
      emit(const EmailVerificationVerified());
    } else {
      emit(const EmailVerificationFailed("Verification link is invalid or has expired."));
    }
  }

  Future<void> checkVerificationStatus({required String uid}) async {
    emit(const EmailVerificationVerifying());
    final verified = await _repository.checkVerificationStatus(uid);
    if (verified) {
      emit(const EmailVerificationVerified());
    } else {
      emit(const EmailVerificationFailed("We couldn't confirm your verification. Please click the link in your email first."));
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    int seconds = 60;
    emit(EmailVerificationCooldown(seconds));
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds--;
      if (seconds > 0) {
        emit(EmailVerificationCooldown(seconds));
      } else {
        _cooldownTimer?.cancel();
        emit(const EmailVerificationSent());
      }
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
