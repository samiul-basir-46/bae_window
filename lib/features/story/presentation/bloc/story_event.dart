import 'package:flutter/foundation.dart';
import 'story_state.dart';

@immutable
abstract class StoryEvent {
  const StoryEvent();
}

class LoadMemoriesEvent extends StoryEvent {
  const LoadMemoriesEvent();
}

class ChangeFilterEvent extends StoryEvent {
  final StoryFilter filter;
  const ChangeFilterEvent(this.filter);
}

class AddMemoryEvent extends StoryEvent {
  final String title;
  final String note;
  final String imageUrl;
  final bool isMilestone;
  final bool isPrivate;
  final String layoutType;

  const AddMemoryEvent({
    required this.title,
    required this.note,
    required this.imageUrl,
    required this.isMilestone,
    required this.isPrivate,
    required this.layoutType,
  });
}

class UnlockVaultEvent extends StoryEvent {
  const UnlockVaultEvent();
}

class LockVaultEvent extends StoryEvent {
  const LockVaultEvent();
}

class DeleteMemoryEvent extends StoryEvent {
  final String id;
  const DeleteMemoryEvent(this.id);
}

class EditMemoryNoteEvent extends StoryEvent {
  final String id;
  final String newNote;
  const EditMemoryNoteEvent({required this.id, required this.newNote});
}

class MoveToVaultEvent extends StoryEvent {
  final String id;
  final bool isPrivate;
  const MoveToVaultEvent({required this.id, required this.isPrivate});
}

class SetupVaultPinEvent extends StoryEvent {
  final String pin;
  final bool enableBiometrics;
  const SetupVaultPinEvent({required this.pin, required this.enableBiometrics});
}

class ToggleBiometricsEvent extends StoryEvent {
  final bool enabled;
  const ToggleBiometricsEvent(this.enabled);
}

