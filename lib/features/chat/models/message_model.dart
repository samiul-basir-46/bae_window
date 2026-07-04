import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageType { text, image, video, file }

enum MessageStatus { sending, sent, delivered, seen }

class RepliedMessageModel {
  final String messageId;
  final String senderId;
  final String content;
  final ChatMessageType type;

  RepliedMessageModel({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.type,
  });

  factory RepliedMessageModel.fromMap(Map<String, dynamic> map) {
    return RepliedMessageModel(
      messageId: map['messageId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      content: map['content'] as String? ?? '',
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'text'),
        orElse: () => ChatMessageType.text,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'content': content,
      'type': type.name,
    };
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final ChatMessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final RepliedMessageModel? repliedTo;
  final Map<String, String> reactions; // userId -> emoji
  final String? fileName;
  final int? fileSize;
  final bool isEdited;
  final String? videoThumbnail;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.repliedTo,
    this.reactions = const {},
    this.fileName,
    this.fileSize,
    this.isEdited = false,
    this.videoThumbnail,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime dt;
    final ts = map['timestamp'];
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else if (ts is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(ts);
    } else if (ts is String) {
      dt = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      dt = DateTime.now();
    }

    final reactionsMap = <String, String>{};
    if (map['reactions'] is Map) {
      (map['reactions'] as Map).forEach((k, v) {
        reactionsMap[k.toString()] = v.toString();
      });
    }

    return MessageModel(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      content: map['content'] as String? ?? '',
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'text'),
        orElse: () => ChatMessageType.text,
      ),
      timestamp: dt,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      repliedTo: map['repliedTo'] != null
          ? RepliedMessageModel.fromMap(map['repliedTo'] as Map<String, dynamic>)
          : null,
      reactions: reactionsMap,
      fileName: map['fileName'] as String?,
      fileSize: map['fileSize'] as int?,
      isEdited: map['isEdited'] as bool? ?? false,
      videoThumbnail: map['videoThumbnail'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'repliedTo': repliedTo?.toMap(),
      'reactions': reactions,
      'fileName': fileName,
      'fileSize': fileSize,
      'isEdited': isEdited,
      'videoThumbnail': videoThumbnail,
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? content,
    ChatMessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    RepliedMessageModel? repliedTo,
    Map<String, String>? reactions,
    String? fileName,
    int? fileSize,
    bool? isEdited,
    String? videoThumbnail,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      repliedTo: repliedTo ?? this.repliedTo,
      reactions: reactions ?? this.reactions,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      isEdited: isEdited ?? this.isEdited,
      videoThumbnail: videoThumbnail ?? this.videoThumbnail,
    );
  }
}
