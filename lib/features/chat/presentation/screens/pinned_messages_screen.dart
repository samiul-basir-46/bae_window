import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:intl/intl.dart';

import 'package:bea_window_app/features/chat/models/user_model.dart';

class PinnedMessagesScreen extends StatelessWidget {
  final String conversationId;
  final UserModel partnerUser;

  const PinnedMessagesScreen({
    super.key,
    required this.conversationId,
    required this.partnerUser,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .snapshots(),
      builder: (context, convSnapshot) {
        final convData = convSnapshot.data?.data() ?? {};
        final nicknames = convData['nicknames'] as Map<String, dynamic>? ?? {};

        final partnerNickname = nicknames[partnerUser.uid] as String? ?? '';
        final partnerDisplayName = partnerNickname.isNotEmpty
            ? partnerNickname
            : partnerUser.displayName;

        return Scaffold(
          backgroundColor: AppColors.softBlack,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20.sp, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Pinned Messages",
              style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold),
            ),
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('conversations')
                .doc(conversationId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: BaeLoader());
              }
              final allDocs = snapshot.data?.docs ?? [];
              final docs = allDocs.where((doc) {
                return doc.data()['isPinned'] as bool? ?? false;
              }).toList();

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    "No pinned messages yet.",
                    style: GoogleFonts.dmSans(
                        color: Colors.white38, fontSize: 13.sp),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final msg = MessageModel.fromMap(doc.id, doc.data());
                  final isMe = msg.senderId == currentUserId;

                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isMe ? "You" : partnerDisplayName,
                              style: GoogleFonts.dmSans(
                                color: isMe
                                    ? AppColors.primaryPink
                                    : Colors.white70,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd, hh:mm a')
                                  .format(msg.timestamp),
                              style: GoogleFonts.dmSans(
                                  color: Colors.white30, fontSize: 10.sp),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        if (msg.type == ChatMessageType.image)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.network(msg.content,
                                height: 120.h, fit: BoxFit.cover),
                          )
                        else if (msg.type == ChatMessageType.video)
                          Container(
                            height: 120.h,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                                child: Icon(Icons.play_circle_fill_rounded,
                                    color: Colors.white, size: 40.sp)),
                          )
                        else
                          Text(
                            msg.content,
                            style: GoogleFonts.dmSans(
                                color: Colors.white, fontSize: 13.sp),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
