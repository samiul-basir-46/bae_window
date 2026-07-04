import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/features/chat/models/user_model.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final MessageModel? lastMessage;
  final Map<String, int> unreadCounts;
  final Map<String, DateTime> lastSeen;
  final Map<String, bool> typing;
  final Map<String, int> muteSettings;
  final DateTime updatedAt;
  final bool isGroup;
  final DateTime createdAt;
  final UserModel? otherUser; // populated dynamically at presentation layer

  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.unreadCounts = const {},
    this.lastSeen = const {},
    this.typing = const {},
    this.muteSettings = const {},
    required this.updatedAt,
    this.isGroup = false,
    required this.createdAt,
    this.otherUser,
  });

  factory ConversationModel.fromMap(String id, Map<String, dynamic> map, {UserModel? otherUser}) {
    DateTime updatedDt;
    final updatedTs = map['updatedAt'];
    if (updatedTs is Timestamp) {
      updatedDt = updatedTs.toDate();
    } else if (updatedTs is int) {
      updatedDt = DateTime.fromMillisecondsSinceEpoch(updatedTs);
    } else if (updatedTs is String) {
      updatedDt = DateTime.tryParse(updatedTs) ?? DateTime.now();
    } else {
      updatedDt = DateTime.now();
    }

    DateTime createdDt;
    final createdTs = map['createdAt'];
    if (createdTs is Timestamp) {
      createdDt = createdTs.toDate();
    } else if (createdTs is int) {
      createdDt = DateTime.fromMillisecondsSinceEpoch(createdTs);
    } else if (createdTs is String) {
      createdDt = DateTime.tryParse(createdTs) ?? DateTime.now();
    } else {
      createdDt = DateTime.now();
    }

    final unreadMap = <String, int>{};
    if (map['unreadCounts'] is Map) {
      (map['unreadCounts'] as Map).forEach((k, v) {
        unreadMap[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    }

    final seenMap = <String, DateTime>{};
    if (map['lastSeen'] is Map) {
      (map['lastSeen'] as Map).forEach((k, v) {
        if (v is Timestamp) {
          seenMap[k.toString()] = v.toDate();
        } else if (v is int) {
          seenMap[k.toString()] = DateTime.fromMillisecondsSinceEpoch(v);
        } else if (v is String) {
          seenMap[k.toString()] = DateTime.tryParse(v) ?? DateTime.now();
        }
      });
    }

    final typingMap = <String, bool>{};
    if (map['typing'] is Map) {
      (map['typing'] as Map).forEach((k, v) {
        typingMap[k.toString()] = v as bool? ?? false;
      });
    }

    final muteMap = <String, int>{};
    if (map['muteSettings'] is Map) {
      (map['muteSettings'] as Map).forEach((k, v) {
        muteMap[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    }

    MessageModel? lastMsg;
    if (map['lastMessage'] != null && map['lastMessage'] is Map) {
      final lastMsgData = map['lastMessage'] as Map<String, dynamic>;
      final lastMsgId = lastMsgData['id'] as String? ?? '';
      lastMsg = MessageModel.fromMap(lastMsgId, lastMsgData);
    }

    final participantsList = <String>[];
    if (map['participants'] is List) {
      for (final p in map['participants'] as List) {
        participantsList.add(p.toString());
      }
    }

    return ConversationModel(
      id: id,
      participants: participantsList,
      lastMessage: lastMsg,
      unreadCounts: unreadMap,
      lastSeen: seenMap,
      typing: typingMap,
      muteSettings: muteMap,
      updatedAt: updatedDt,
      isGroup: map['isGroup'] as bool? ?? false,
      createdAt: createdDt,
      otherUser: otherUser,
    );
  }

  Map<String, dynamic> toMap() {
    final seenMapRaw = <String, dynamic>{};
    lastSeen.forEach((k, v) {
      seenMapRaw[k] = Timestamp.fromDate(v);
    });

    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage?.toMap(),
      'unreadCounts': unreadCounts,
      'lastSeen': seenMapRaw,
      'typing': typing,
      'muteSettings': muteSettings,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isGroup': isGroup,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ConversationModel copyWith({
    String? id,
    List<String>? participants,
    MessageModel? lastMessage,
    Map<String, int>? unreadCounts,
    Map<String, DateTime>? lastSeen,
    Map<String, bool>? typing,
    Map<String, int>? muteSettings,
    DateTime? updatedAt,
    bool? isGroup,
    DateTime? createdAt,
    UserModel? otherUser,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      lastSeen: lastSeen ?? this.lastSeen,
      typing: typing ?? this.typing,
      muteSettings: muteSettings ?? this.muteSettings,
      updatedAt: updatedAt ?? this.updatedAt,
      isGroup: isGroup ?? this.isGroup,
      createdAt: createdAt ?? this.createdAt,
      otherUser: otherUser ?? this.otherUser,
    );
  }
}
