import 'package:flutter/foundation.dart';

@immutable
abstract class StoryState {
  const StoryState();
}

class StoryInitial extends StoryState {
  const StoryInitial();
}

class StoryLoading extends StoryState {
  const StoryLoading();
}

enum StoryFilter { all, milestones }

class StoryLoaded extends StoryState {
  final List<MemoryItem> memories;
  final StoryFilter selectedFilter;

  const StoryLoaded({
    required this.memories,
    required this.selectedFilter,
  });

  StoryLoaded copyWith({
    List<MemoryItem>? memories,
    StoryFilter? selectedFilter,
  }) {
    return StoryLoaded(
      memories: memories ?? this.memories,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class StoryUploading extends StoryState {
  final List<MemoryItem> memories;
  final String progressMessage;
  final StoryFilter selectedFilter;

  const StoryUploading({
    required this.memories,
    required this.progressMessage,
    required this.selectedFilter,
  });
}

class StoryError extends StoryState {
  final String message;
  const StoryError(this.message);
}

class MemoryItem {
  final String id;
  final String imageUrl;
  final List<String> images;
  final String title;
  final String note;
  final String dateString; // e.g. "June 22, 2026"
  final DateTime dateTime;
  final String uploadedBy; // "You" or "Bae" / PartnerName
  final bool isMilestone;
  final String layoutType; // "full" or "grid"

  const MemoryItem({
    required this.id,
    required this.imageUrl,
    this.images = const [],
    required this.title,
    required this.note,
    required this.dateString,
    required this.dateTime,
    required this.uploadedBy,
    required this.isMilestone,
    required this.layoutType,
  });

  MemoryItem copyWith({
    String? id,
    String? imageUrl,
    List<String>? images,
    String? title,
    String? note,
    String? dateString,
    DateTime? dateTime,
    String? uploadedBy,
    bool? isMilestone,
    String? layoutType,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      title: title ?? this.title,
      note: note ?? this.note,
      dateString: dateString ?? this.dateString,
      dateTime: dateTime ?? this.dateTime,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      isMilestone: isMilestone ?? this.isMilestone,
      layoutType: layoutType ?? this.layoutType,
    );
  }
}
