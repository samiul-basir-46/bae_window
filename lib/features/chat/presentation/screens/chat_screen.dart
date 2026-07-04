import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/features/chat/bloc/chat_bloc.dart';
import 'package:bea_window_app/features/chat/bloc/chat_event.dart';
import 'package:bea_window_app/features/chat/bloc/chat_state.dart';
import 'package:bea_window_app/features/chat/bloc/upload_bloc.dart';
import 'package:bea_window_app/features/chat/bloc/upload_event.dart';
import 'package:bea_window_app/features/chat/bloc/upload_state.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/features/chat/models/user_model.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/date_separator.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/empty_chat_widget.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/loading_widget.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/message_input.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/reply_preview.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/reaction_picker.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/upload_progress_widget.dart';
import 'package:bea_window_app/features/chat/repositories/chat_repository.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/di.dart';

class ChatScreen extends StatelessWidget {
  final String? conversationId;
  final String? partnerUid;

  const ChatScreen({
    super.key,
    this.conversationId,
    this.partnerUid,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final resolvedConvId = conversationId ?? 
        ([currentUserId, partnerUid ?? '']..sort()).join('_');

    return MultiBlocProvider(
      providers: [
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc()..add(LoadMessagesEvent(resolvedConvId)),
        ),
        BlocProvider<UploadBloc>(
          create: (context) => UploadBloc(),
        ),
      ],
      child: ChatView(
        conversationId: resolvedConvId,
        partnerUid: partnerUid ?? '',
      ),
    );
  }
}

class ChatView extends StatefulWidget {
  final String conversationId;
  final String partnerUid;

  const ChatView({
    super.key,
    required this.conversationId,
    required this.partnerUid,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _chatRepository = locator<ChatRepository>();
  
  UserModel? _partnerUser;
  MessageModel? _editingMessage;
  OverlayEntry? _reactionOverlayEntry;
  StreamSubscription<UserModel>? _partnerProfileSub;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPartnerProfile();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _partnerProfileSub?.cancel();
    _dismissReactionPicker();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // In reversed ListView, scrolling to top means position.pixels is near maxScrollExtent
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<ChatBloc>().add(LoadMoreMessagesEvent());
      }
    }
  }

  void _loadPartnerProfile() async {
    _partnerUser = await _chatRepository.getUserProfile(widget.partnerUid);
    if (mounted) setState(() {});

    // Listen to real-time changes in partner's profile (isOnline, lastActive, etc.)
    await _partnerProfileSub?.cancel();
    _partnerProfileSub = _chatRepository.watchUserProfile(widget.partnerUid).listen((user) {
      if (mounted) {
        setState(() {
          _partnerUser = user;
        });
      }
    });
  }

  void _showReactionPicker(BuildContext context, MessageModel message, Offset position) {
    _dismissReactionPicker();
    _reactionOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _dismissReactionPicker,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              // Place the reaction bar slightly above the long press coordinates
              top: (position.dy - 64.h).clamp(50.h, MediaQuery.of(context).size.height - 100.h),
              left: (position.dx - 150.w).clamp(16.w, MediaQuery.of(context).size.width - 320.w),
              child: ReactionPicker(
                onReactionSelected: (emoji) {
                  context.read<ChatBloc>().add(AddReactionEvent(messageId: message.id, emoji: emoji));
                  _dismissReactionPicker();
                },
                onDismiss: _dismissReactionPicker,
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_reactionOverlayEntry!);
  }

  void _dismissReactionPicker() {
    _reactionOverlayEntry?.remove();
    _reactionOverlayEntry = null;
  }

  void _showLongPressMenu(BuildContext context, MessageModel message, Offset position) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwnMessage = message.senderId == currentUserId;

    _showReactionPicker(context, message, position);

    // If it's the sender's own text message, show an options dialog too
    if (isOwnMessage && message.type == ChatMessageType.text) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: AppColors.navBgColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_rounded, color: Colors.white70),
                    title: const Text('Edit Message', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      setState(() {
                        _editingMessage = message;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.softBlack,
      appBar: _partnerUser != null
          ? ChatAppBar(
              partnerUser: _partnerUser!,
              isTyping: context.watch<ChatBloc>().state.isRecipientTyping,
            )
          : AppBar(
              backgroundColor: AppColors.navBgColor,
              elevation: 0,
              title: const Text('Chat'),
            ),
      body: BlocListener<UploadBloc, UploadState>(
        listener: (context, state) {
          if (state is UploadSuccess) {
            final type = context.read<UploadBloc>().state is UploadingState 
                ? ChatMessageType.text // fallback
                : (state.thumbnailUrl != null ? ChatMessageType.video : ChatMessageType.image);
            
            // Auto-trigger message send upon media upload completion
            context.read<ChatBloc>().add(SendMediaMessageEvent(
              content: state.mediaUrl,
              type: type,
              videoThumbnail: state.thumbnailUrl,
            ));
          } else if (state is UploadFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: ${state.error}')),
            );
          }
        },
        child: Column(
          children: [
            // Message Feed list
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(child: LoadingWidget());
                  }

                  final messages = state.messages;
                  if (messages.isEmpty) {
                    return const EmptyChatWidget(
                      title: 'Say hello!',
                      subtitle: 'No messages in this chat. Type a message below to start chatting.',
                    );
                  }

                  // Construct visual list containing date separators
                  final List<Widget> listItems = [];
                  for (int i = 0; i < messages.length; i++) {
                    final msg = messages[i];
                    final showAvatar = i == messages.length - 1 || messages[i + 1].senderId != msg.senderId;

                    listItems.add(
                      MessageBubble(
                        message: msg,
                        isMe: msg.senderId == currentUserId,
                        showAvatar: showAvatar,
                        senderName: _partnerUser?.displayName ?? 'Partner',
                        senderAvatarUrl: _partnerUser?.profilePicture,
                        partnerAvatarUrl: _partnerUser?.profilePicture,
                        isLastMessage: i == 0,
                        onSwipeToReply: (messageToReply) {
                          context.read<ChatBloc>().add(ReplyToMessageEvent(messageToReply));
                        },
                        onLongPressMessage: (messageToReact, position) {
                          _showLongPressMenu(context, messageToReact, position);
                        },
                      ),
                    );

                    // Add date separators dynamically
                    if (i < messages.length - 1) {
                      final nextMsg = messages[i + 1];
                      if (msg.timestamp.day != nextMsg.timestamp.day ||
                          msg.timestamp.month != nextMsg.timestamp.month ||
                          msg.timestamp.year != nextMsg.timestamp.year) {
                        listItems.add(DateSeparator(date: msg.timestamp));
                      }
                    } else {
                      // Last message
                      listItems.add(DateSeparator(date: msg.timestamp));
                    }
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: listItems.length,
                    itemBuilder: (context, index) => listItems[index],
                  );
                },
              ),
            ),

            // Upload progress display
            BlocBuilder<UploadBloc, UploadState>(
              builder: (context, state) {
                if (state is UploadingState) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: UploadProgressWidget(
                      progress: state.progress,
                      onCancel: () {
                        context.read<UploadBloc>().add(CancelUploadEvent());
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Reply Preview panel
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.replyingTo != null) {
                  final replyUser = state.replyingTo!.senderId == currentUserId
                      ? 'You'
                      : (_partnerUser?.displayName ?? 'Partner');
                  return ReplyPreview(
                    message: state.replyingTo!,
                    senderName: replyUser,
                    onCancel: () {
                      context.read<ChatBloc>().add(const ReplyToMessageEvent(null));
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Text Input bar
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return MessageInput(
                  editingMessage: _editingMessage,
                  onSendText: (text) {
                    context.read<ChatBloc>().add(SendTextMessageEvent(text));
                  },
                  onSendMedia: (file, type) {
                    context.read<UploadBloc>().add(StartMediaUploadEvent(
                      file: file,
                      conversationId: widget.conversationId,
                      type: type,
                    ));
                  },
                  onTypingChanged: (isTyping) {
                    context.read<ChatBloc>().add(UpdateTypingEvent(isTyping));
                  },
                  onCancelEdit: () {
                    setState(() {
                      _editingMessage = null;
                    });
                  },
                  onFinishEdit: (newText) {
                    if (_editingMessage != null) {
                      context.read<ChatBloc>().add(EditMessageEvent(
                        messageId: _editingMessage!.id,
                        newContent: newText,
                      ));
                      setState(() {
                        _editingMessage = null;
                      });
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
