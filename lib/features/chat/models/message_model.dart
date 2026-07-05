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

class MediaItemModel {
  final String url;
  final ChatMessageType type;
  final String? thumbnail;

  MediaItemModel({
    required this.url,
    required this.type,
    this.thumbnail,
  });

  factory MediaItemModel.fromMap(Map<String, dynamic> map) {
    return MediaItemModel(
      url: map['url'] as String? ?? '',
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'image'),
        orElse: () => ChatMessageType.image,
      ),
      thumbnail: map['thumbnail'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'type': type.name,
      if (thumbnail != null) 'thumbnail': thumbnail,
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
  final bool isPinned;
  final bool isDeleted;
  final List<String> deletedFor;
  final List<MediaItemModel>? mediaItems;

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
    this.isPinned = false,
    this.isDeleted = false,
    this.deletedFor = const [],
    this.mediaItems,
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

    final deletedForList = <String>[];
    if (map['deletedFor'] is List) {
      deletedForList.addAll(List<String>.from(map['deletedFor'] as List));
    }

    List<MediaItemModel>? mediaItemsList;
    if (map['mediaItems'] is List) {
      mediaItemsList = (map['mediaItems'] as List)
          .map((item) => MediaItemModel.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
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
      isPinned: map['isPinned'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      deletedFor: deletedForList,
      mediaItems: mediaItemsList,
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
      'isPinned': isPinned,
      'isDeleted': isDeleted,
      'deletedFor': deletedFor,
      if (mediaItems != null)
        'mediaItems': mediaItems!.map((item) => item.toMap()).toList(),
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
    bool? isPinned,
    bool? isDeleted,
    List<String>? deletedFor,
    List<MediaItemModel>? mediaItems,
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
      isPinned: isPinned ?? this.isPinned,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedFor: deletedFor ?? this.deletedFor,
      mediaItems: mediaItems ?? this.mediaItems,
    );
  }
}
