part of 'email_cubit.dart';

enum EmailStatus { initial, loading, success, failure }

class EmailState {
  final EmailStatus status;
  final String? errorMessage;

  const EmailState({
    this.status = EmailStatus.initial,
    this.errorMessage,
  });

  EmailState copyWith({
    EmailStatus? status,
    String? errorMessage,
  }) {
    return EmailState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}
