import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/features/chat/bloc/chat_event.dart';
import 'package:bea_window_app/features/chat/bloc/chat_state.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/features/chat/repositories/chat_repository.dart';
import 'package:bea_window_app/helpers/di.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository = locator<ChatRepository>();
  StreamSubscription<List<MessageModel>>? _messagesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _convSub;
  String? _currentUserId;
  String? _partnerUserId;

  ChatBloc() : super(const ChatInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<UpdateMessagesEvent>(_onUpdateMessages);
    on<SendTextMessageEvent>(_onSendTextMessage);
    on<SendMediaMessageEvent>(_onSendMediaMessage);
    on<ReplyToMessageEvent>(_onReplyToMessage);
    on<EditMessageEvent>(_onEditMessage);
    on<UpdateTypingEvent>(_onUpdateTyping);
    on<AddReactionEvent>(_onAddReaction);
    on<RemoveReactionEvent>(_onRemoveReaction);
    on<MarkAsSeenEvent>(_onMarkAsSeen);
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(ChatError(conversationId: event.conversationId, errorMsg: 'Authentication failed.'));
      return;
    }
    _currentUserId = user.uid;

    emit(ChatLoading(conversationId: event.conversationId));

    // Resolve partner UID from the conversation UIDs
    try {
      final convDoc = await FirebaseFirestore.instance.collection('conversations').doc(event.conversationId).get();
      if (convDoc.exists) {
        final participants = List<String>.from(convDoc.data()?['participants'] ?? []);
        _partnerUserId = participants.firstWhere((uid) => uid != _currentUserId, orElse: () => '');
      }
    } catch (_) {}

    await _messagesSub?.cancel();
    _messagesSub = _chatRepository
        .getMessagesStream(event.conversationId, 20)
        .listen((messages) {
      add(UpdateMessagesEvent(messages));
    }, onError: (err) {
      if (!isClosed) {
        emit(ChatError(conversationId: event.conversationId, errorMsg: err.toString()));
      }
    });

    // Subscribe to typing indicator status changes from the conversation doc
    await _convSub?.cancel();
    _convSub = FirebaseFirestore.instance
        .collection('conversations')
        .doc(event.conversationId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null && _partnerUserId != null && _partnerUserId!.isNotEmpty) {
        final typingMap = snapshot.data()!['typing'] as Map?;
        final partnerIsTyping = typingMap?[_partnerUserId] as bool? ?? false;
        
        if (state is ChatLoaded && !isClosed) {
          final currentState = state as ChatLoaded;
          if (currentState.isRecipientTyping != partnerIsTyping) {
            emit(currentState.copyWith(isRecipientTyping: partnerIsTyping));
          }
        }
      }
    });

    // Mark all current messages in the room as seen
    add(MarkAsSeenEvent());
  }

  void _onLoadMoreMessages(
    LoadMoreMessagesEvent event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      if (!currentState.hasMore) return;

      final newLimit = currentState.limit + 20;

      // Re-subscribe to messages stream with higher pagination limit
      _messagesSub?.cancel();
      _messagesSub = _chatRepository
          .getMessagesStream(currentState.conversationId, newLimit)
          .listen((messages) {
        add(UpdateMessagesEvent(messages));
      }, onError: (err) {
        if (!isClosed) {
          emit(ChatError(
            conversationId: currentState.conversationId,
            errorMsg: err.toString(),
            messages: currentState.messages,
            limit: currentState.limit,
            hasMore: currentState.hasMore,
          ));
        }
      });
    }
  }

  void _onUpdateMessages(
    UpdateMessagesEvent event,
    Emitter<ChatState> emit,
  ) {
    final conversationId = state.conversationId;
    final currentLimit = state.limit;
    
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

    emit(ChatLoaded(
      conversationId: conversationId,
      messages: event.messages,
      limit: currentLimit,
      hasMore: hasMore,
      isRecipientTyping: isTyping,
      replyingTo: replyToMsg,
    ));

    // Instantly mark messages as read if we receive incoming items while active in room
    add(MarkAsSeenEvent());
  }

  Future<void> _onSendTextMessage(
    SendTextMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded && _currentUserId != null) {
      final currentState = state as ChatLoaded;
      final text = event.content.trim();
      if (text.isEmpty) return;

      RepliedMessageModel? repliedToModel;
      if (currentState.replyingTo != null) {
        repliedToModel = RepliedMessageModel(
          messageId: currentState.replyingTo!.id,
          senderId: currentState.replyingTo!.senderId,
          content: currentState.replyingTo!.content,
          type: currentState.replyingTo!.type,
        );
      }

      // Clear draft message
      _chatRepository.clearMessageDraft(currentState.conversationId);

      // Clear reply state locally
      emit(currentState.copyWith(replyingTo: () => null));

      try {
        await _chatRepository.sendMessage(
          conversationId: currentState.conversationId,
          senderId: _currentUserId!,
          content: text,
          type: ChatMessageType.text,
          repliedTo: repliedToModel,
        );
      } catch (err) {
        if (!isClosed) {
          emit(currentState.copyWith(error: () => err.toString()));
        }
      }
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

      emit(currentState.copyWith(replyingTo: () => null));

      try {
        await _chatRepository.sendMessage(
          conversationId: currentState.conversationId,
          senderId: _currentUserId!,
          content: event.content,
          type: event.type,
          repliedTo: repliedToModel,
          fileName: event.fileName,
          fileSize: event.fileSize,
          videoThumbnail: event.videoThumbnail,
        );
      } catch (err) {
        if (!isClosed) {
          emit(currentState.copyWith(error: () => err.toString()));
        }
      }
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
      } catch (_) {}
    }
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();
    _convSub?.cancel();
    // Reset typing status on exit
    if (_currentUserId != null && state.conversationId.isNotEmpty) {
      _chatRepository.setTypingStatus(
        conversationId: state.conversationId,
        userId: _currentUserId!,
        isTyping: false,
      );
    }
    return super.close();
  }
}
