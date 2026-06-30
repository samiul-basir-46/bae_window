import 'package:flutter/foundation.dart';

@immutable
abstract class NotificationSettingsEvent {
  const NotificationSettingsEvent();
}

class LoadNotificationSettingsEvent extends NotificationSettingsEvent {
  const LoadNotificationSettingsEvent();
}

class ToggleSettingEvent extends NotificationSettingsEvent {
  final String key;
  final bool value;
  const ToggleSettingEvent(this.key, this.value);
}

class UpdateQuietHoursEvent extends NotificationSettingsEvent {
  final String? start;
  final String? end;
  const UpdateQuietHoursEvent({this.start, this.end});
}
