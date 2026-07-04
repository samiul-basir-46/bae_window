import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/features/chat/bloc/inbox_bloc.dart';
import 'package:bea_window_app/features/chat/bloc/inbox_event.dart';
import 'package:bea_window_app/features/chat/bloc/inbox_state.dart';
import 'package:bea_window_app/features/chat/models/user_model.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/conversation_tile.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/empty_chat_widget.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/loading_widget.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:cached_network_image/cached_network_image.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InboxBloc>(
      create: (context) => InboxBloc()
        ..add(LoadInboxConversationsEvent())
        ..add(LoadUsersListEvent()),
      child: const InboxView(),
    );
  }
}

class InboxView extends StatefulWidget {
  const InboxView({super.key});

  @override
  State<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<InboxView> {
  final TextEditingController _searchController = TextEditingController();

  void _startChatWithUser(BuildContext context, UserModel otherUser) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Generate unique conversation ID sorting UIDs lexicographically
    final uids = [currentUser.uid, otherUser.uid]..sort();
    final conversationId = uids.join('_');

    // Open chat screen immediately, passing conversation data
    Navigator.pushNamed(
      context,
      Routes.chatScreen,
      arguments: {
        'conversationId': conversationId,
        'partnerUid': otherUser.uid,
      },
    );
  }

  void _showNewChatDialog(BuildContext context, InboxLoaded state) {
    final inboxBloc = context.read<InboxBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.softBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      isScrollControlled: true,
      builder: (modalContext) {
        return BlocProvider.value(
          value: inboxBloc,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.75,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                child: Column(
                  children: [
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'New Message',
                      style: TextFontStyle.textStyle16cFFFFFFDMSans600,
                    ),
                    SizedBox(height: 16.h),
                    // Search bar in bottom sheet
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (val) {
                          inboxBloc.add(SearchUsersEvent(val));
                        },
                        decoration: InputDecoration(
                          hintText: 'Search people...',
                          hintStyle: TextStyle(color: Colors.white30, fontSize: 13.sp),
                          prefixIcon: const Icon(Icons.search, color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Expanded(
                      child: BlocBuilder<InboxBloc, InboxState>(
                        builder: (context, innerState) {
                          if (innerState is InboxLoaded) {
                            final users = innerState.filteredUsers;
                            if (users.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No users found',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return ListTile(
                                  onTap: () {
                                    Navigator.pop(modalContext);
                                    _startChatWithUser(context, user);
                                  },
                                  contentPadding: EdgeInsets.symmetric(vertical: 4.h),
                                  leading: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 22.r,
                                        backgroundColor: Colors.white10,
                                        backgroundImage: user.profilePicture != null &&
                                                user.profilePicture!.isNotEmpty
                                            ? CachedNetworkImageProvider(user.profilePicture!)
                                            : null,
                                        child: user.profilePicture == null ||
                                                user.profilePicture!.isEmpty
                                            ? Icon(Icons.person, color: Colors.white30, size: 20.sp)
                                            : null,
                                      ),
                                      if (user.isOnline)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 12.r,
                                            height: 12.r,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.green,
                                              border: Border.all(
                                                color: AppColors.softBlack,
                                                width: 1.5.w,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    user.displayName,
                                    style: TextFontStyle.textStyle14cFFFFFFDMSans600,
                                  ),
                                  subtitle: Text(
                                    user.isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      color: user.isOnline ? Colors.green : AppColors.c8E8E9F,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      // Clear query filter on dialog dismiss
      inboxBloc.add(const SearchUsersEvent(''));
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.softBlack,
      body: Stack(
        children: [
          // Background visual highlights
          Positioned(
            top: -100.h,
            left: -50.w,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryPink.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100.h,
            right: -100.w,
            child: Container(
              width: 350.w,
              height: 350.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryPurple.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content layout
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header bar
                Padding(
                  padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 16.h, bottom: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chats',
                        style: TextFontStyle.textStyle20cFFFFFFDMSans600.copyWith(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      BlocBuilder<InboxBloc, InboxState>(
                        builder: (context, state) {
                          if (state is InboxLoaded) {
                            return GestureDetector(
                              onTap: () => _showNewChatDialog(context, state),
                              child: Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    width: 1.w,
                                  ),
                                ),
                                child: Icon(
                                  Icons.edit_note_rounded,
                                  size: 24.sp,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.02),
                        width: 1.w,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) {
                        // Extensible option: local search over conversations or start user query
                      },
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        hintStyle: TextStyle(
                          color: AppColors.c8E8E9F.withValues(alpha: 0.4),
                          fontSize: 13.sp,
                        ),
                        prefixIcon: const Icon(Icons.search, color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ),

                // Active conversation stream
                Expanded(
                  child: BlocBuilder<InboxBloc, InboxState>(
                    builder: (context, state) {
                      if (state is InboxLoading || state is InboxInitial) {
                        return const Center(child: LoadingWidget());
                      } else if (state is InboxError) {
                        return Center(
                          child: Text(
                            state.message,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      } else if (state is InboxLoaded) {
                        final list = state.conversations;
                        if (list.isEmpty) {
                          return const EmptyChatWidget(
                            title: 'No chats yet',
                            subtitle: 'Tap the edit icon in the top right to start a chat with someone!',
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<InboxBloc>().add(LoadInboxConversationsEvent());
                          },
                          color: AppColors.primaryPink,
                          backgroundColor: AppColors.navBgColor,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final conv = list[index];
                              return ConversationTile(
                                conversation: conv,
                                currentUserId: currentUserId,
                                onTap: () {
                                  final otherUser = conv.otherUser;
                                  Navigator.pushNamed(
                                    context,
                                    Routes.chatScreen,
                                    arguments: {
                                      'conversationId': conv.id,
                                      'partnerUid': otherUser?.uid ?? '',
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
