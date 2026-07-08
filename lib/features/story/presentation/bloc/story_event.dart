import 'dart:io';
import 'package:flutter/foundation.dart';
import 'story_state.dart';

@immutable
abstract class StoryEvent {
  const StoryEvent();
}

class LoadStoriesEvent extends StoryEvent {
  final String coupleId;
  final String currentUserUid;
  final String currentUserName;
  final String partnerName;
  final bool forceRefresh;

  const LoadStoriesEvent({
    required this.coupleId,
    required this.currentUserUid,
    required this.currentUserName,
    required this.partnerName,
    this.forceRefresh = false,
  });
}

class ChangeFilterEvent extends StoryEvent {
  final StoryFilter filter;
  const ChangeFilterEvent(this.filter);
}

class AddMemoryEvent extends StoryEvent {
  final String title;
  final String note;
  final File? imageFile;
  final List<File> additionalImageFiles;
  final bool isMilestone;
  final String layoutType;

  const AddMemoryEvent({
    required this.title,
    required this.note,
    this.imageFile,
    this.additionalImageFiles = const [],
    required this.isMilestone,
    required this.layoutType,
  });
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
