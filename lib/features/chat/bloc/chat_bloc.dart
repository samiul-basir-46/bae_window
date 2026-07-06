import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/features/chat/bloc/chat_event.dart';
import 'package:bea_window_app/features/chat/bloc/chat_state.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/features/chat/repositories/chat_repository.dart';
import 'package:bea_window_app/helpers/notification_service.dart';
import 'package:bea_window_app/helpers/di.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository = locator<ChatRepository>();
  StreamSubscription<List<MessageModel>>? _messagesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _convSub;
  String? _currentUserId;
  String? _partnerUserId;
  final List<MessageModel> _pendingMessages = [];
  List<MessageModel> _remoteMessages = [];

  ChatBloc() : super(const ChatInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<UpdateMessagesEvent>(_onUpdateMessages);
    on<SendTextMessageEvent>(_onSendTextMessage);
    on<SendMediaMessageEvent>(_onSendMediaMessage);
    on<SendMultipleMediaMessageEvent>(_onSendMultipleMediaMessage);
    on<ReplyToMessageEvent>(_onReplyToMessage);
    on<EditMessageEvent>(_onEditMessage);
    on<UpdateTypingEvent>(_onUpdateTyping);
    on<UpdateRecipientTypingEvent>(_onUpdateRecipientTyping);
    on<AddReactionEvent>(_onAddReaction);
    on<RemoveReactionEvent>(_onRemoveReaction);
    on<MarkAsSeenEvent>(_onMarkAsSeen);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<RetrySendMessageEvent>(_onRetrySendMessage);
    on<_UpdatePendingMessageStatusEvent>(_onUpdatePendingMessageStatus);
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(ChatError(
          conversationId: event.conversationId,
          errorMsg: 'Authentication failed.'));
      return;
    }
    _currentUserId = user.uid;

    final conversationId = event.conversationId;
    final parts = conversationId.split('_');
    _partnerUserId = parts.firstWhere((id) => id != _currentUserId,
        orElse: () => '');

    emit(ChatLoading(
      conversationId: conversationId,
      limit: state.limit,
    ));

    await _messagesSub?.cancel();
    _messagesSub = _chatRepository
        .getMessagesStream(conversationId, state.limit)
        .listen((messages) {
      add(UpdateMessagesEvent(messages));
    });

    await _convSub?.cancel();
    _convSub = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final typing = data['typing'] ?? {};
          final isPartnerTyping = typing[_partnerUserId] ?? false;
          add(UpdateRecipientTypingEvent(isPartnerTyping));
        }
      }
    });
  }

  void _onLoadMoreMessages(
    LoadMoreMessagesEvent event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatLoaded && state.hasMore) {
      final currentLimit = state.limit;
      final newLimit = currentLimit + 20;

      // Update subscription with the new limit
      _messagesSub?.cancel();
      _messagesSub = _chatRepository
          .getMessagesStream(state.conversationId, newLimit)
          .listen((messages) {
        add(UpdateMessagesEvent(messages));
      });

      emit((state as ChatLoaded).copyWith(limit: newLimit));
    }
  }

  void _onUpdateMessages(
    UpdateMessagesEvent event,
    Emitter<ChatState> emit,
  ) {
    final conversationId = state.conversationId;
    final currentLimit = state.limit;

    // Filter out messages that the user deleted/hid for themselves
    final filteredMessages = event.messages
        .where((msg) => !msg.deletedFor.contains(_currentUserId ?? ''))
        .toList();

    final deletedMessageIds = event.messages
        .where((msg) => msg.isDeleted || msg.deletedFor.contains(_currentUserId ?? ''))
        .map((msg) => msg.id)
        .toSet();

    // If the number of messages returned is less than the current query limit,
    // we have fetched all messages from history.
    final hasMore = event.messages.length >= currentLimit;

    bool isTyping = false;
    MessageModel? replyToMsg;
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      isTyping = currentState.isRecipientTyping;
      replyToMsg = currentState.replyingTo;
    }

    if (replyToMsg != null && deletedMessageIds.contains(replyToMsg.id)) {
      replyToMsg = null;
    }

    _remoteMessages = filteredMessages;

    emit(ChatLoaded(
      conversationId: conversationId,
      messages: _getMergedMessages(),
      limit: currentLimit,
      hasMore: hasMore,
      isRecipientTyping: isTyping,
      replyingTo: replyToMsg,
      deletedMessageIds: deletedMessageIds,
    ));

    add(MarkAsSeenEvent());
  }

  Future<void> _onSendTextMessage(
    SendTextMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded && _currentUserId != null) {
      final currentState = state as ChatLoaded;

      RepliedMessageModel? repliedToModel;
      if (currentState.replyingTo != null) {
        repliedToModel = RepliedMessageModel(
          messageId: currentState.replyingTo!.id,
          senderId: currentState.replyingTo!.senderId,
          content: currentState.replyingTo!.content,
          type: currentState.replyingTo!.type,
        );
      }

      final String msgId = FirebaseFirestore.instance
          .collection('conversations')
          .doc(currentState.conversationId)
          .collection('messages')
          .doc()
          .id;

      final pendingMsg = MessageModel(
        id: msgId,
        senderId: _currentUserId!,
        content: event.content,
        type: ChatMessageType.text,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
        repliedTo: repliedToModel,
      );

      _pendingMessages.add(pendingMsg);
      emit(currentState.copyWith(
        messages: _getMergedMessages(),
        replyingTo: () => null,
      ));

      _uploadMessageInBackground(
        conversationId: currentState.conversationId,
        message: pendingMsg,
      );
    }
  }

  Future<void> _onSendMediaMessage(
    SendMediaMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded && _currentUserId != null) {
      final currentState = state as ChatLoaded;

      RepliedMessageModel? repliedToModel;
      if (currentState.replyingTo != null) {
        repliedToModel = RepliedMessageModel(
          messageId: currentState.replyingTo!.id,
          senderId: currentState.replyingTo!.senderId,
          content: currentState.replyingTo!.content,
          type: currentState.replyingTo!.type,
        );
      }

      final String msgId = FirebaseFirestore.instance
          .collection('conversations')
          .doc(currentState.conversationId)
          .collection('messages')
          .doc()
          .id;

      final pendingMsg = MessageModel(
        id: msgId,
        senderId: _currentUserId!,
        content: event.content,
        type: event.type,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
        repliedTo: repliedToModel,
        fileName: event.fileName,
        fileSize: event.fileSize,
        videoThumbnail: event.videoThumbnail,
      );

      _pendingMessages.add(pendingMsg);
      emit(currentState.copyWith(
        messages: _getMergedMessages(),
        replyingTo: () => null,
      ));

      _uploadMessageInBackground(
        conversationId: currentState.conversationId,
        message: pendingMsg,
      );
    }
  }

  Future<void> _onSendMultipleMediaMessage(
    SendMultipleMediaMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded && _currentUserId != null) {
      final currentState = state as ChatLoaded;

      RepliedMessageModel? repliedToModel;
      if (currentState.replyingTo != null) {
        repliedToModel = RepliedMessageModel(
          messageId: currentState.replyingTo!.id,
          senderId: currentState.replyingTo!.senderId,
          content: currentState.replyingTo!.content,
          type: currentState.replyingTo!.type,
        );
      }

      final String msgId = FirebaseFirestore.instance
          .collection('conversations')
          .doc(currentState.conversationId)
          .collection('messages')
          .doc()
          .id;

      final pendingMsg = MessageModel(
        id: msgId,
        senderId: _currentUserId!,
        content: event.textContent ?? '',
        type: ChatMessageType.image,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
        repliedTo: repliedToModel,
        mediaItems: event.mediaItems,
      );

      _pendingMessages.add(pendingMsg);
      emit(currentState.copyWith(
        messages: _getMergedMessages(),
        replyingTo: () => null,
      ));

      _uploadMessageInBackground(
        conversationId: currentState.conversationId,
        message: pendingMsg,
      );
    }
  }

  void _onReplyToMessage(
    ReplyToMessageEvent event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(currentState.copyWith(replyingTo: () => event.message));
    }
  }

  Future<void> _onEditMessage(
    EditMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      try {
        await _chatRepository.editMessage(
          conversationId: currentState.conversationId,
          messageId: event.messageId,
          newContent: event.newContent,
        );
      } catch (err) {
        if (!isClosed) {
          emit(currentState.copyWith(error: () => err.toString()));
        }
      }
    }
  }

  Future<void> _onUpdateTyping(
    UpdateTypingEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (_currentUserId != null && state.conversationId.isNotEmpty) {
      try {
        await _chatRepository.setTypingStatus(
          conversationId: state.conversationId,
          userId: _currentUserId!,
          isTyping: event.isTyping,
        );
      } catch (_) {}
    }
  }

  Future<void> _onAddReaction(
    AddReactionEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded && _currentUserId != null) {
      final currentState = state as ChatLoaded;
      try {
        await _chatRepository.addReaction(
          conversationId: currentState.conversationId,
          messageId: event.messageId,
          userId: _currentUserId!,
          emoji: event.emoji,
        );
      } catch (err) {
        if (!isClosed) {
          emit(currentState.copyWith(error: () => err.toString()));
        }
      }
    }
  }

  Future<void> _onRemoveReaction(
    RemoveReactionEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded && _currentUserId != null) {
      final currentState = state as ChatLoaded;
      try {
        await _chatRepository.removeReaction(
          conversationId: currentState.conversationId,
          messageId: event.messageId,
          userId: _currentUserId!,
        );
      } catch (err) {
        if (!isClosed) {
          emit(currentState.copyWith(error: () => err.toString()));
        }
      }
    }
  }

  Future<void> _onMarkAsSeen(
    MarkAsSeenEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (_currentUserId != null && state.conversationId.isNotEmpty) {
      try {
        await _chatRepository.markMessagesAsSeen(
          conversationId: state.conversationId,
          currentUserId: _currentUserId!,
        );
        // Clear local notifications for this conversation
        unawaited(PushNotificationService.clearConversationNotifications(
            state.conversationId));
      } catch (_) {}
    }
  }

  void _onUpdateRecipientTyping(
    UpdateRecipientTypingEvent event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      if (currentState.isRecipientTyping != event.isTyping) {
        emit(currentState.copyWith(isRecipientTyping: event.isTyping));
      }
    }
  }

  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded && _currentUserId != null) {
      final currentState = state as ChatLoaded;
      final isOwnMessage = event.message.senderId == _currentUserId;

      try {
        await _chatRepository.deleteMessage(
          conversationId: currentState.conversationId,
          messageId: event.message.id,
          userId: _currentUserId!,
          deleteForEveryone: isOwnMessage,
        );
      } catch (err) {
        if (!isClosed) {
          emit(currentState.copyWith(error: () => err.toString()));
        }
      }
    }
  }

  @override
  Future<void> close() async {
    _messagesSub?.cancel();
    _convSub?.cancel();

    if (_currentUserId != null && state.conversationId.isNotEmpty) {
      try {
        await _chatRepository.markMessagesAsSeen(
          conversationId: state.conversationId,
          currentUserId: _currentUserId!,
        );
        await _chatRepository.setTypingStatus(
          conversationId: state.conversationId,
          userId: _currentUserId!,
          isTyping: false,
        );
      } catch (_) {}
    }
    return super.close();
  }

  List<MessageModel> _getMergedMessages() {
    final remoteIds = _remoteMessages.map((m) => m.id).toSet();
    final uniquePending = _pendingMessages.where((pm) => !remoteIds.contains(pm.id)).toList();
    final merged = [...uniquePending, ..._remoteMessages];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged;
  }

  void _uploadMessageInBackground({
    required String conversationId,
    required MessageModel message,
  }) {
    unawaited(() async {
      try {
        await _chatRepository.sendMessage(
          conversationId: conversationId,
          senderId: message.senderId,
          content: message.content,
          type: message.type,
          repliedTo: message.repliedTo,
          fileName: message.fileName,
          fileSize: message.fileSize,
          videoThumbnail: message.videoThumbnail,
          mediaItems: message.mediaItems,
          messageId: message.id,
        );
        add(_UpdatePendingMessageStatusEvent(
          messageId: message.id,
          status: MessageStatus.sent,
          remove: true,
        ));
      } catch (err) {
        add(_UpdatePendingMessageStatusEvent(
          messageId: message.id,
          status: MessageStatus.failed,
          remove: false,
        ));
      }
    }());
  }

  void _onRetrySendMessage(
    RetrySendMessageEvent event,
    Emitter<ChatState> emit,
  ) {
    final index = _pendingMessages.indexWhere((m) => m.id == event.messageId);
    if (index != -1) {
      _pendingMessages[index] = _pendingMessages[index].copyWith(status: MessageStatus.sending);
      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(messages: _getMergedMessages()));
        _uploadMessageInBackground(
          conversationId: state.conversationId,
          message: _pendingMessages[index],
        );
      }
    }
  }

  void _onUpdatePendingMessageStatus(
    _UpdatePendingMessageStatusEvent event,
    Emitter<ChatState> emit,
  ) {
    if (event.remove) {
      _pendingMessages.removeWhere((m) => m.id == event.messageId);
    } else {
      final index = _pendingMessages.indexWhere((m) => m.id == event.messageId);
      if (index != -1) {
        _pendingMessages[index] = _pendingMessages[index].copyWith(status: event.status);
      }
    }
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(messages: _getMergedMessages()));
    }
  }
}

class _UpdatePendingMessageStatusEvent extends ChatEvent {
  final String messageId;
  final MessageStatus status;
  final bool remove;
  const _UpdatePendingMessageStatusEvent({
    required this.messageId,
    required this.status,
    required this.remove,
  });
}
