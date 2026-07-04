import 'package:bea_window_app/features/chat/models/message_model.dart';

abstract class ChatEvent {
  const ChatEvent();
}

class LoadMessagesEvent extends ChatEvent {
  final String conversationId;
  const LoadMessagesEvent(this.conversationId);
}

class LoadMoreMessagesEvent extends ChatEvent {}

class UpdateMessagesEvent extends ChatEvent {
  final List<MessageModel> messages;
  const UpdateMessagesEvent(this.messages);
}

class SendTextMessageEvent extends ChatEvent {
  final String content;
  const SendTextMessageEvent(this.content);
}

class SendMediaMessageEvent extends ChatEvent {
  final String content;
  final ChatMessageType type;
  final String? fileName;
  final int? fileSize;
  final String? videoThumbnail;

  const SendMediaMessageEvent({
    required this.content,
    required this.type,
    this.fileName,
    this.fileSize,
    this.videoThumbnail,
  });
}

class ReplyToMessageEvent extends ChatEvent {
  final MessageModel? message;
  const ReplyToMessageEvent(this.message);
}

class EditMessageEvent extends ChatEvent {
  final String messageId;
  final String newContent;
  const EditMessageEvent({required this.messageId, required this.newContent});
}

class UpdateTypingEvent extends ChatEvent {
  final bool isTyping;
  const UpdateTypingEvent(this.isTyping);
}

class AddReactionEvent extends ChatEvent {
  final String messageId;
  final String emoji;
  const AddReactionEvent({required this.messageId, required this.emoji});
}

class RemoveReactionEvent extends ChatEvent {
  final String messageId;
  const RemoveReactionEvent(this.messageId);
}

class MarkAsSeenEvent extends ChatEvent {}
