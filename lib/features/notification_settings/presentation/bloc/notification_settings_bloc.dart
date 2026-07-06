import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bea_window_app/helpers/notification_service.dart';
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

  Future<void> _onLoadSettings(
    LoadNotificationSettingsEvent event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final localState = NotificationSettingsState(
      newSnap: _storage.read('newSnap') ?? true,
      drawingNote: _storage.read('drawingNote') ?? true,
      thinkingPulse: _storage.read('thinkingPulse') ?? true,
      voiceFragment: _storage.read('voiceFragment') ?? true,
      taskCompleted: _storage.read('taskCompleted') ?? true,
      moodCheckIn: _storage.read('moodCheckIn') ?? false,
      milestoneReminders: _storage.read('milestoneReminders') ?? true,
      vaultActivity: _storage.read('vaultActivity') ?? true,
      quietHoursEnabled: _storage.read('quietHoursEnabled') ?? true,
      quietHoursStart: _storage.read('quietHoursStart') ?? "11:00 PM",
      quietHoursEnd: _storage.read('quietHoursEnd') ?? "07:00 AM",
    );
    emit(localState);

    try {
      final remoteSettings = await PushNotificationService.loadSettings();
      final syncedState = remoteSettings == null
          ? localState
          : NotificationSettingsState.fromMap(remoteSettings);
      if (remoteSettings == null) {
        await PushNotificationService.saveSettings(localState.toMap());
      } else {
        await _writeLocalSettings(syncedState);
        emit(syncedState);
      }
      await PushNotificationService.requestPermissionAndRegister();
    } catch (_) {
      // Local preferences remain usable while offline and sync on next load.
    }
  }

  Future<void> _onToggleSetting(
    ToggleSettingEvent event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    NotificationSettingsState? nextState;
    switch (event.key) {
      case 'newSnap':
        nextState = state.copyWith(newSnap: event.value);
        break;
      case 'drawingNote':
        nextState = state.copyWith(drawingNote: event.value);
        break;
      case 'thinkingPulse':
        nextState = state.copyWith(thinkingPulse: event.value);
        break;
      case 'voiceFragment':
        nextState = state.copyWith(voiceFragment: event.value);
        break;
      case 'taskCompleted':
        nextState = state.copyWith(taskCompleted: event.value);
        break;
      case 'moodCheckIn':
        nextState = state.copyWith(moodCheckIn: event.value);
        break;
      case 'milestoneReminders':
        nextState = state.copyWith(milestoneReminders: event.value);
        break;
      case 'vaultActivity':
        nextState = state.copyWith(vaultActivity: event.value);
        break;
      case 'quietHoursEnabled':
        nextState = state.copyWith(quietHoursEnabled: event.value);
        break;
    }
    if (nextState == null) return;

    emit(nextState);
    await _storage.write(event.key, event.value);
    try {
      await PushNotificationService.saveSettings(nextState.toMap());
    } catch (_) {
      // Keep the local choice and retry when settings are opened again.
    }
  }

  Future<void> _onUpdateQuietHours(
    UpdateQuietHoursEvent event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    var nextState = state;
    if (event.start != null) {
      await _storage.write('quietHoursStart', event.start);
      nextState = nextState.copyWith(quietHoursStart: event.start);
    }
    if (event.end != null) {
      await _storage.write('quietHoursEnd', event.end);
      nextState = nextState.copyWith(quietHoursEnd: event.end);
    }
    emit(nextState);
    try {
      await PushNotificationService.saveSettings(nextState.toMap());
    } catch (_) {
      // Keep the local choice and retry when settings are opened again.
    }
  }

  Future<void> _writeLocalSettings(NotificationSettingsState settings) async {
    for (final entry in settings.toMap().entries) {
      await _storage.write(entry.key, entry.value);
    }
  }
}
