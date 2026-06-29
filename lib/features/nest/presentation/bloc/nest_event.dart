import 'package:flutter/foundation.dart';

@immutable
abstract class NestEvent {
  const NestEvent();
}

class LoadNestEvent extends NestEvent {
  const LoadNestEvent();
}

class ToggleVaultLockEvent extends NestEvent {
  final bool isLocked;
  const ToggleVaultLockEvent(this.isLocked);
}

class ToggleFocusModeEvent extends NestEvent {
  final bool isFocus;
  const ToggleFocusModeEvent(this.isFocus);
}

class ChangeThemeEvent extends NestEvent {
  final String theme; // "Light", "Dark", "Auto"
  const ChangeThemeEvent(this.theme);
}

class SwapConnectionAvatarsEvent extends NestEvent {
  const SwapConnectionAvatarsEvent();
}
