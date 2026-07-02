import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/email_repository.dart';

part 'email_state.dart';

class EmailCubit extends Cubit<EmailState> {
  final EmailRepository _repository;

  EmailCubit(this._repository) : super(const EmailState());

  Future<void> sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
    String name = '',
  }) async {
    dev.log('Starting sendEmail process: to=$to, subject=$subject, name=$name');
    emit(state.copyWith(status: EmailStatus.loading));

    final success = await _repository.sendEmail(
      to: to,
      subject: subject,
      htmlContent: htmlContent,
      name: name,
    );

    if (success) {
      dev.log('Email sent successfully to=$to');
      emit(state.copyWith(status: EmailStatus.success));
    } else {
      dev.log('Failed to send email to=$to');
      emit(state.copyWith(
        status: EmailStatus.failure,
        errorMessage: 'Email পাঠাতে সমস্যা হয়েছে, আবার চেষ্টা করুন।',
      ));
    }
  }
}

