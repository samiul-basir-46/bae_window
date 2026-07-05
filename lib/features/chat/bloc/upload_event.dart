import 'dart:io';
import 'package:bea_window_app/features/chat/models/message_model.dart';

abstract class UploadEvent {
  const UploadEvent();
}

class StartMediaUploadEvent extends UploadEvent {
  final File file;
  final String conversationId;
  final ChatMessageType type;

  const StartMediaUploadEvent({
    required this.file,
    required this.conversationId,
    required this.type,
  });
}

class StartMultipleMediaUploadEvent extends UploadEvent {
  final List<File> files;
  final List<ChatMessageType> types;
  final String conversationId;

  const StartMultipleMediaUploadEvent({
    required this.files,
    required this.types,
    required this.conversationId,
  });
}

class UpdateUploadProgressEvent extends UploadEvent {
  final double progress;
  const UpdateUploadProgressEvent(this.progress);
}

class CancelUploadEvent extends UploadEvent {}

class RetryUploadEvent extends UploadEvent {}
