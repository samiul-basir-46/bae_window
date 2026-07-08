import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/helpers/firestore_cache_service.dart';
import 'package:intl/intl.dart';

class SearchConversationScreen extends StatefulWidget {
  final String conversationId;

  const SearchConversationScreen({super.key, required this.conversationId});

  @override
  State<SearchConversationScreen> createState() =>
      _SearchConversationScreenState();
}

class _SearchConversationScreenState extends State<SearchConversationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreCacheService _cache = FirestoreCacheService.instance;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
        title: TextField(
          controller: _searchController,
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14.sp),
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Search in conversation...",
            hintStyle:
                GoogleFonts.dmSans(color: Colors.white30, fontSize: 14.sp),
            border: InputBorder.none,
          ),
          onChanged: (val) {
            setState(() {
              _query = val.trim();
            });
          },
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white60),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                });
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? Center(
              child: Text(
                "Type a word to search message history",
                style:
                    GoogleFonts.dmSans(color: Colors.white38, fontSize: 13.sp),
              ),
            )
          : FutureBuilder<List<MessageModel>>(
              future: _searchMessages(_query),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: BaeLoader());
                }
                final results = snapshot.data!;

                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      "No matches found.",
                      style: GoogleFonts.dmSans(
                          color: Colors.white38, fontSize: 13.sp),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final msg = results[index];
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
                                isMe ? "You" : "Partner",
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
  }

  Future<List<MessageModel>> _searchMessages(String query) async {
    final docs = await _cache.getCollection(
      query: FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .where('type', isEqualTo: 'text')
          .limit(100),
      cacheKey: 'conversations/${widget.conversationId}/search_text_100',
      ttl: const Duration(minutes: 5),
    );

    return docs
        .map((data) => MessageModel.fromMap(data['id'] as String? ?? '', data))
        .where((msg) => msg.content.toLowerCase().contains(query.toLowerCase()))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
