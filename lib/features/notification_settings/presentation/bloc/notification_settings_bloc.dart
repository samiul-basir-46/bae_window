import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'notification_settings_event.dart';
import 'notification_settings_state.dart';

class NotificationSettingsBloc
    extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  final _storage = GetStorage();

  NotificationSettingsBloc() : super(const NotificationSettingsState()) {
    on<LoadNotificationSettingsEvent>(_onLoadSettings);
    on<ToggleSettingEvent>(_onToggleSetting);
    on<UpdateQuietHoursEvent>(_onUpdateQuietHours);
  }

  void _onLoadSettings(
    LoadNotificationSettingsEvent event,
    Emitter<NotificationSettingsState> emit,
  ) {
    emit(NotificationSettingsState(
      newSnap: _storage.read('newSnap') ?? true,
      drawingNote: _storage.read('drawingNote') ?? true,
      thinkingPulse: _storage.read('thinkingPulse') ?? true,
      voiceFragment: _storage.read('voiceFragment') ?? true,
      taskCompleted: _storage.read('taskCompleted') ?? true,
      moodCheckIn: _storage.read('moodCheckIn') ?? false,
      milestoneReminders: _storage.read('milestoneReminders') ?? true,
      quietHoursEnabled: _storage.read('quietHoursEnabled') ?? true,
      quietHoursStart: _storage.read('quietHoursStart') ?? "11:00 PM",
      quietHoursEnd: _storage.read('quietHoursEnd') ?? "07:00 AM",
    ));
  }

  void _onToggleSetting(
    ToggleSettingEvent event,
    Emitter<NotificationSettingsState> emit,
  ) {
    _storage.write(event.key, event.value);
    
    switch (event.key) {
      case 'newSnap':
        emit(state.copyWith(newSnap: event.value));
        break;
      case 'drawingNote':
        emit(state.copyWith(drawingNote: event.value));
        break;
      case 'thinkingPulse':
        emit(state.copyWith(thinkingPulse: event.value));
        break;
      case 'voiceFragment':
        emit(state.copyWith(voiceFragment: event.value));
        break;
      case 'taskCompleted':
        emit(state.copyWith(taskCompleted: event.value));
        break;
      case 'moodCheckIn':
        emit(state.copyWith(moodCheckIn: event.value));
        break;
      case 'milestoneReminders':
        emit(state.copyWith(milestoneReminders: event.value));
        break;
      case 'quietHoursEnabled':
        emit(state.copyWith(quietHoursEnabled: event.value));
        break;
    }
  }

  void _onUpdateQuietHours(
    UpdateQuietHoursEvent event,
    Emitter<NotificationSettingsState> emit,
  ) {
    if (event.start != null) {
      _storage.write('quietHoursStart', event.start);
      emit(state.copyWith(quietHoursStart: event.start));
    }
    if (event.end != null) {
      _storage.write('quietHoursEnd', event.end);
      emit(state.copyWith(quietHoursEnd: event.end));
    }
  }
}
