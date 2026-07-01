import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialDayModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime createdAt;

  SpecialDayModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  SpecialDayModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return SpecialDayModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SpecialDayModel.fromMap(Map<String, dynamic> map, String docId) {
    return SpecialDayModel(
      id: docId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
