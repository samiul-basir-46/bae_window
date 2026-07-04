import 'package:bea_window_app/features/chat/models/message_model.dart';

abstract class ChatState {
  final String conversationId;
  final List<MessageModel> messages;
  final int limit;
  final bool hasMore;
  final MessageModel? replyingTo;
  final bool isRecipientTyping;
  final bool isLoading;
  final String? error;

  const ChatState({
    required this.conversationId,
    this.messages = const [],
    this.limit = 20,
    this.hasMore = true,
    this.replyingTo,
    this.isRecipientTyping = false,
    this.isLoading = false,
    this.error,
  });
}

class ChatInitial extends ChatState {
  const ChatInitial() : super(conversationId: '');
}

class ChatLoading extends ChatState {
  const ChatLoading({required super.conversationId, super.limit});
}

class ChatLoaded extends ChatState {
  const ChatLoaded({
    required super.conversationId,
    required super.messages,
    required super.limit,
    required super.hasMore,
    super.replyingTo,
    super.isRecipientTyping,
    super.isLoading,
    super.error,
  });

  ChatLoaded copyWith({
    List<MessageModel>? messages,
    int? limit,
    bool? hasMore,
    MessageModel? Function()? replyingTo,
    bool? isRecipientTyping,
    bool? isLoading,
    String? Function()? error,
  }) {
    return ChatLoaded(
      conversationId: conversationId,
      messages: messages ?? this.messages,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
      replyingTo: replyingTo != null ? replyingTo() : this.replyingTo,
      isRecipientTyping: isRecipientTyping ?? this.isRecipientTyping,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

class ChatError extends ChatState {
  const ChatError({
    required super.conversationId,
    required String errorMsg,
    super.messages,
    super.limit,
    super.hasMore,
  }) : super(error: errorMsg);
}
