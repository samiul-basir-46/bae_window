import 'dart:developer' as dev;

import 'package:bea_window_app/helpers/notification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskNotificationCubit extends Cubit<bool> {
  TaskNotificationCubit() : super(false);

  Future<void> notifyTaskCompleted(String taskTitle) async {
    if (state) return;
    emit(true);
    try {
      await PushNotificationService.createTaskCompletedEvent(taskTitle);
    } catch (e, stack) {
      dev.log(
        'Could not create task notification event',
        name: 'TaskNotificationCubit',
        error: e,
        stackTrace: stack,
      );
    } finally {
      emit(false);
    }
  }
}
