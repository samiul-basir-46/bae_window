import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/features/chat/bloc/inbox_bloc.dart';
import 'package:bea_window_app/features/chat/bloc/inbox_event.dart';
import 'package:bea_window_app/features/chat/bloc/inbox_state.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/conversation_tile.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/empty_chat_widget.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/loading_widget.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bea_window_app/features/chat/models/conversation_model.dart';
import 'package:bea_window_app/helpers/notification_service.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

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

  void _showConversationOptionsSheet(BuildContext context, ConversationModel conv, String currentUserId) {
    final muteExpiry = conv.muteSettings[currentUserId] ?? 0;
    final isMuted = muteExpiry == -1 || (muteExpiry > 0 && DateTime.now().millisecondsSinceEpoch < muteExpiry);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              ListTile(
                leading: Icon(Icons.mark_chat_read_rounded, color: Colors.white, size: 20.sp),
                title: Text('Mark as Read', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                onTap: () async {
                  Navigator.pop(context);
                  // Mark as read in Firestore
                  try {
                    final convRef = FirebaseFirestore.instance.collection('conversations').doc(conv.id);
                    await convRef.update({
                      'unreadCounts.$currentUserId': 0,
                      'lastSeen.$currentUserId': FieldValue.serverTimestamp(),
                    });
                    
                    // Cancel push notifications
                    await PushNotificationService.clearConversationNotifications(conv.id);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Conversation marked as read'), duration: Duration(seconds: 2)),
                      );
                    }
                  } catch (_) {}
                },
              ),
              ListTile(
                leading: Icon(isMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: Colors.white, size: 20.sp),
                title: Text(isMuted ? 'Unmute Notifications' : 'Mute Notifications', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                onTap: () async {
                  Navigator.pop(context);
                  if (isMuted) {
                    // Unmute
                    GetStorage().remove('mute_until_${conv.id}');
                    await FirebaseFirestore.instance.collection('conversations').doc(conv.id).set({
                      'muteSettings': {
                        currentUserId: FieldValue.delete(),
                      }
                    }, SetOptions(merge: true));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications unmuted'), duration: Duration(seconds: 2)),
                      );
                    }
                  } else {
                    // Show mute duration dialog helper
                    _showMuteDurationPicker(context, conv.id, currentUserId);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMuteDurationPicker(BuildContext context, String conversationId, String currentUserId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        final options = [
          {'label': '5 Minutes', 'duration': const Duration(minutes: 5)},
          {'label': '10 Minutes', 'duration': const Duration(minutes: 10)},
          {'label': '1 Hour', 'duration': const Duration(hours: 1)},
          {'label': '8 Hours', 'duration': const Duration(hours: 8)},
          {'label': '1 Day', 'duration': const Duration(days: 1)},
          {'label': 'Forever (Until I change it)', 'duration': null},
        ];

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
                child: Text(
                  'Mute Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((opt) {
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        title: Text(
                          opt['label'] as String,
                          style: TextStyle(color: Colors.white, fontSize: 14.sp),
                        ),
                        onTap: () async {
                          final duration = opt['duration'] as Duration?;
                          final expiry = duration != null
                              ? DateTime.now().add(duration).millisecondsSinceEpoch
                              : -1;
                          
                          GetStorage().write('mute_until_$conversationId', expiry);
                          
                          await FirebaseFirestore.instance.collection('conversations').doc(conversationId).set({
                            'muteSettings': {
                              currentUserId: expiry,
                            }
                          }, SetOptions(merge: true));

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Notifications muted for ${opt['label']}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              UIHelper.verticalSpace(12.h),
            ],
          ),
        );
      },
    );
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
                                onLongPress: () => _showConversationOptionsSheet(context, conv, currentUserId),
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
