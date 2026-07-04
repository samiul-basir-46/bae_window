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

class UpdateUploadProgressEvent extends UploadEvent {
  final double progress;
  const UpdateUploadProgressEvent(this.progress);
}

class CancelUploadEvent extends UploadEvent {}

class RetryUploadEvent extends UploadEvent {}
