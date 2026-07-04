import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'chat_screen.dart';

class BaeChatLoader extends StatefulWidget {
  const BaeChatLoader({super.key});

  @override
  State<BaeChatLoader> createState() => _BaeChatLoaderState();
}

class _BaeChatLoaderState extends State<BaeChatLoader> {
  String? _partnerUid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartner();
  }

  Future<void> _loadPartner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['pairStatus'] == 'paired') {
            final pairId = userData['pairId'] as String?;
            if (pairId != null && pairId.isNotEmpty) {
              final coupleDoc = await FirebaseFirestore.instance.collection('couples').doc(pairId).get();
              if (coupleDoc.exists) {
                final coupleData = coupleDoc.data();
                if (coupleData != null) {
                  final user1Uid = coupleData['user1Uid'] as String?;
                  final user2Uid = coupleData['user2Uid'] as String?;
                  _partnerUid = (user1Uid == user.uid) ? user2Uid : user1Uid;
                }
              }
            }
          }
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.softBlack,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryPink)),
      );
    }

    if (_partnerUid == null) {
      return const Scaffold(
        backgroundColor: AppColors.softBlack,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Pair with your partner first to start chatting! ✦',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return ChatScreen(partnerUid: _partnerUid);
  }
}
