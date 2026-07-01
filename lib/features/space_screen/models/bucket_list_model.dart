import 'package:cloud_firestore/cloud_firestore.dart';

class BucketListItem {
  final String id;
  final String title;
  final String description;
  final String date;
  final bool isCompleted;
  final double progress;
  final DateTime createdAt;

  const BucketListItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.isCompleted,
    required this.progress,
    required this.createdAt,
  });

  BucketListItem copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    bool? isCompleted,
    double? progress,
    DateTime? createdAt,
  }) {
    return BucketListItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'isCompleted': isCompleted,
      'progress': progress,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BucketListItem.fromMap(Map<String, dynamic> map, String docId) {
    return BucketListItem(
      id: docId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      date: map['date'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
