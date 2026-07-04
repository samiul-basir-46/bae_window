import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String? nickname;
  final String? profilePicture;
  final bool isOnline;
  final DateTime? lastActive;
  final String? pairId;
  final String? pairStatus;

  UserModel({
    required this.uid,
    required this.name,
    this.nickname,
    this.profilePicture,
    this.isOnline = false,
    this.lastActive,
    this.pairId,
    this.pairStatus,
  });

  String get displayName => nickname != null && nickname!.isNotEmpty ? nickname! : name;

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    DateTime? lastActiveDateTime;
    final lastActiveField = map['lastActive'];
    if (lastActiveField is Timestamp) {
      lastActiveDateTime = lastActiveField.toDate();
    } else if (lastActiveField is int) {
      lastActiveDateTime = DateTime.fromMillisecondsSinceEpoch(lastActiveField);
    } else if (lastActiveField is String) {
      lastActiveDateTime = DateTime.tryParse(lastActiveField);
    }

    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? 'User',
      nickname: map['nickname'] as String?,
      profilePicture: map['profilePicture'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      lastActive: lastActiveDateTime,
      pairId: map['pairId'] as String?,
      pairStatus: map['pairStatus'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nickname': nickname,
      'profilePicture': profilePicture,
      'isOnline': isOnline,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'pairId': pairId,
      'pairStatus': pairStatus,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? nickname,
    String? profilePicture,
    bool? isOnline,
    DateTime? lastActive,
    String? pairId,
    String? pairStatus,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      profilePicture: profilePicture ?? this.profilePicture,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      pairId: pairId ?? this.pairId,
      pairStatus: pairStatus ?? this.pairStatus,
    );
  }
}
