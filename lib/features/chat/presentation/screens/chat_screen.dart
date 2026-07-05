import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:get_storage/get_storage.dart';
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
    final resolvedConvId =
        conversationId ?? ([currentUserId, partnerUid ?? '']..sort()).join('_');

    return MultiBlocProvider(
      providers: [
        BlocProvider<ChatBloc>(
          create: (context) =>
              ChatBloc()..add(LoadMessagesEvent(resolvedConvId)),
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
  StreamSubscription<UserModel>? _partnerProfileSub;

  bool _showScrollToBottomButton = false;
  String? _pendingMediaCaption;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPartnerProfile();
    // Suppress notifications for this conversation while active
    GetStorage().write('active_conversation_id', widget.conversationId);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _partnerProfileSub?.cancel();
    GetStorage().remove('active_conversation_id');
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // In reversed ListView, scrolling to top means position.pixels is near maxScrollExtent
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<ChatBloc>().add(LoadMoreMessagesEvent());
      }

      final showButton = _scrollController.position.pixels > 300;
      if (showButton != _showScrollToBottomButton) {
        setState(() {
          _showScrollToBottomButton = showButton;
        });
      }
    }
  }

  void _loadPartnerProfile() async {
    _partnerUser = await _chatRepository.getUserProfile(widget.partnerUid);
    if (mounted) setState(() {});

    // Listen to real-time changes in partner's profile (isOnline, lastActive, etc.)
    await _partnerProfileSub?.cancel();
    _partnerProfileSub =
        _chatRepository.watchUserProfile(widget.partnerUid).listen((user) {
      if (mounted) {
        setState(() {
          _partnerUser = user;
        });
      }
    });
  }

  void _showLongPressMenu(
      BuildContext context, MessageModel message, Offset position) {
    if (message.isDeleted) return;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwnMessage = message.senderId == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (modalContext) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Swipe/Drag handle
              Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Reactions row
              ReactionPicker(
                onReactionSelected: (emoji) {
                  context.read<ChatBloc>().add(
                      AddReactionEvent(messageId: message.id, emoji: emoji));
                  if (modalContext.mounted) {
                    Navigator.pop(modalContext);
                  }
                },
                onDismiss: () {
                  if (modalContext.mounted) {
                    Navigator.pop(modalContext);
                  }
                },
              ),
              SizedBox(height: 24.h),
              // Action Buttons Grid/List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuActionTile(
                      icon: Icons.reply_rounded,
                      title: 'Reply',
                      onTap: () {
                        Navigator.pop(modalContext);
                        context
                            .read<ChatBloc>()
                            .add(ReplyToMessageEvent(message));
                      },
                    ),
                     _buildMenuActionTile(
                      icon: Icons.copy_all_rounded,
                      title: 'Copy Text',
                      onTap: () {
                        Navigator.pop(modalContext);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          FocusManager.instance.primaryFocus?.unfocus();
                        });
                        Clipboard.setData(ClipboardData(text: message.content));
                      },
                    ),
                    if (isOwnMessage && message.type == ChatMessageType.text)
                      _buildMenuActionTile(
                        icon: Icons.edit_rounded,
                        title: 'Edit Message',
                        onTap: () {
                          Navigator.pop(modalContext);
                          setState(() {
                            _editingMessage = message;
                          });
                        },
                      ),
                    _buildMenuActionTile(
                      icon: Icons.push_pin_rounded,
                      title: message.isPinned ? 'Unpin Message' : 'Pin Message',
                      onTap: () {
                        Navigator.pop(modalContext);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          FocusManager.instance.primaryFocus?.unfocus();
                        });
                        FirebaseFirestore.instance
                            .collection('conversations')
                            .doc(widget.conversationId)
                            .collection('messages')
                            .doc(message.id)
                            .update({'isPinned': !message.isPinned});
                      },
                    ),
                    _buildMenuActionTile(
                      icon: Icons.delete_outline_rounded,
                      title: isOwnMessage ? 'Delete Message' : 'Delete for Me',
                      onTap: () {
                        Navigator.pop(modalContext);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          FocusManager.instance.primaryFocus?.unfocus();
                        });
                        context
                            .read<ChatBloc>()
                            .add(DeleteMessageEvent(message));
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: Colors.white70, size: 22.sp),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
              '🔥 ChatScreen theme StreamBuilder error: ${snapshot.error}');
        }
        final data = snapshot.data?.data() ?? {};
        final themeWallpaper = data['themeWallpaper'] as String?;
        final themeOpacity = (data['themeOpacity'] as num?)?.toDouble() ?? 0.5;
        final quickReaction = data['quickReaction'] as String? ?? '👍';
        final nicknamesMap = Map<String, String>.from(data['nicknames'] ?? {});
        final partnerNickname = nicknamesMap[_partnerUser?.uid];
        final partnerDisplayName =
            partnerNickname != null && partnerNickname.trim().isNotEmpty
                ? partnerNickname
                : (_partnerUser?.displayName ?? 'Partner');

        debugPrint(
            '🍏 ChatScreen StreamBuilder update - conversationId: "${widget.conversationId}", themeWallpaper: "$themeWallpaper", themeOpacity: $themeOpacity');

        return Scaffold(
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          backgroundColor: AppColors.softBlack,
          appBar: _partnerUser != null
              ? ChatAppBar(
                  partnerUser: _partnerUser!,
                  conversationId: widget.conversationId,
                  partnerName: partnerDisplayName,
                  isTyping: context.watch<ChatBloc>().state.isRecipientTyping,
                )
              : AppBar(
                  backgroundColor: AppColors.navBgColor,
                  elevation: 0,
                  title: const Text('Chat'),
                ),
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                if (themeWallpaper != null && themeWallpaper.isNotEmpty)
                  Positioned.fill(
                    child: Opacity(
                      opacity: themeOpacity,
                      child: themeWallpaper.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: themeWallpaper,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.black),
                              errorWidget: (context, url, err) =>
                                  Container(color: Colors.black),
                            )
                          : Image.asset(
                              themeWallpaper,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                Positioned.fill(
                  child: MultiBlocListener(
                    listeners: [
                      BlocListener<UploadBloc, UploadState>(
                        listener: (context, state) {
                          if (state is UploadSuccess) {
                            final type = context.read<UploadBloc>().state
                                    is UploadingState
                                ? ChatMessageType.text // fallback
                                : (state.thumbnailUrl != null
                                    ? ChatMessageType.video
                                    : ChatMessageType.image);

                            // Auto-trigger message send upon media upload completion
                            context.read<ChatBloc>().add(SendMediaMessageEvent(
                                  content: state.mediaUrl,
                                  type: type,
                                  videoThumbnail: state.thumbnailUrl,
                                ));
                          } else if (state is UploadMultipleSuccess) {
                            context.read<ChatBloc>().add(SendMultipleMediaMessageEvent(
                                  mediaItems: state.mediaItems,
                                  textContent: _pendingMediaCaption,
                                ));
                            _pendingMediaCaption = null;
                          } else if (state is UploadFailure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Upload failed: ${state.error}')),
                            );
                          }
                        },
                      ),
                      BlocListener<ChatBloc, ChatState>(
                        listenWhen: (previous, current) {
                          if (previous.messages.length !=
                              current.messages.length) {
                            final prevNewestId = previous.messages.isEmpty
                                ? null
                                : previous.messages.first.id;
                            final currNewestId = current.messages.isEmpty
                                ? null
                                : current.messages.first.id;
                            return prevNewestId != currNewestId;
                          }
                          return false;
                        },
                        listener: (context, state) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              0.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                      ),
                    ],
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
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
                                    subtitle:
                                        'No messages in this chat. Type a message below to start chatting.',
                                  );
                                }

                                // Construct visual list containing date separators
                                final List<Widget> listItems = [];
                                for (int i = 0; i < messages.length; i++) {
                                  final msg = messages[i];
                                  final showAvatar = i == 0 ||
                                      messages[i - 1].senderId != msg.senderId;
                                  listItems.add(
                                    MessageBubble(
                                      message: msg,
                                      isMe: msg.senderId == currentUserId,
                                      showAvatar: showAvatar,
                                      senderName: partnerDisplayName,
                                      senderAvatarUrl:
                                          _partnerUser?.profilePicture,
                                      partnerAvatarUrl:
                                          _partnerUser?.profilePicture,
                                      isLastMessage: i == 0,
                                      isRepliedMessageDeleted:
                                          msg.repliedTo != null &&
                                              state.deletedMessageIds.contains(
                                                  msg.repliedTo!.messageId),
                                      onSwipeToReply: (messageToReply) {
                                        context.read<ChatBloc>().add(
                                            ReplyToMessageEvent(
                                                messageToReply));
                                      },
                                      onLongPressMessage:
                                          (messageToReact, position) {
                                        _showLongPressMenu(
                                            context, messageToReact, position);
                                      },
                                    ),
                                  );

                                  // Add date separators dynamically
                                  if (i < messages.length - 1) {
                                    final nextMsg = messages[i + 1];
                                    if (msg.timestamp.day !=
                                            nextMsg.timestamp.day ||
                                        msg.timestamp.month !=
                                            nextMsg.timestamp.month ||
                                        msg.timestamp.year !=
                                            nextMsg.timestamp.year) {
                                      listItems.add(
                                          DateSeparator(date: msg.timestamp));
                                    }
                                  } else {
                                    // Last message
                                    listItems.add(
                                        DateSeparator(date: msg.timestamp));
                                  }
                                }

                                return ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).padding.top +
                                        76.h,
                                    bottom: 12.h,
                                    left: 8.w,
                                    right: 8.w,
                                  ),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: listItems.length,
                                  itemBuilder: (context, index) =>
                                      listItems[index],
                                );
                              },
                            ),
                          ),

                          // Upload progress display
                          BlocBuilder<UploadBloc, UploadState>(
                            builder: (context, state) {
                              if (state is UploadingState) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 8.h),
                                  child: UploadProgressWidget(
                                    progress: state.progress,
                                    onCancel: () {
                                      context
                                          .read<UploadBloc>()
                                          .add(CancelUploadEvent());
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
                                final replyUser =
                                    state.replyingTo!.senderId == currentUserId
                                        ? 'You'
                                        : partnerDisplayName;
                                return ReplyPreview(
                                  message: state.replyingTo!,
                                  senderName: replyUser,
                                  onCancel: () {
                                    context
                                        .read<ChatBloc>()
                                        .add(const ReplyToMessageEvent(null));
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
                                replyingTo: state.replyingTo,
                                quickReaction: quickReaction,
                                onSendText: (text) {
                                  context
                                      .read<ChatBloc>()
                                      .add(SendTextMessageEvent(text));
                                },
                                onSendMultipleMedia: (files, types, text) {
                                  _pendingMediaCaption = text;
                                  context.read<UploadBloc>().add(
                                        StartMultipleMediaUploadEvent(
                                          files: files,
                                          types: types,
                                          conversationId: widget.conversationId,
                                        ),
                                      );
                                },
                                onTypingChanged: (isTyping) {
                                  context
                                      .read<ChatBloc>()
                                      .add(UpdateTypingEvent(isTyping));
                                },
                                onCancelEdit: () {
                                  setState(() {
                                    _editingMessage = null;
                                  });
                                },
                                onFinishEdit: (newText) {
                                  if (_editingMessage != null) {
                                    context
                                        .read<ChatBloc>()
                                        .add(EditMessageEvent(
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
                  ),
                ),
                Positioned(
                  right: 16.w,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 88.h,
                  child: AnimatedScale(
                    scale: _showScrollToBottomButton ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: () {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            0.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      child: Container(
                        width: 44.r,
                        height: 44.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.navBgColor.withValues(alpha: 0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.primaryPink.withValues(alpha: 0.3),
                            width: 1.5.w,
                          ),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primaryPink,
                          size: 28.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
