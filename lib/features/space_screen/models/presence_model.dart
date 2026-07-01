import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceModel {
  final bool isOnline;
  final DateTime lastActive;

  const PresenceModel({
    required this.isOnline,
    required this.lastActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'isOnline': isOnline,
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  factory PresenceModel.fromMap(Map<String, dynamic> map) {
    return PresenceModel(
      isOnline: map['isOnline'] as bool? ?? false,
      lastActive: map['lastActive'] is Timestamp
          ? (map['lastActive'] as Timestamp).toDate()
          : DateTime.tryParse(map['lastActive']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
