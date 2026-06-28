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

enum StoryFilter { all, milestones, vault }

class StoryLoaded extends StoryState {
  final List<MemoryItem> memories;
  final StoryFilter selectedFilter;
  final bool isVaultUnlocked;

  const StoryLoaded({
    required this.memories,
    required this.selectedFilter,
    required this.isVaultUnlocked,
  });

  StoryLoaded copyWith({
    List<MemoryItem>? memories,
    StoryFilter? selectedFilter,
    bool? isVaultUnlocked,
  }) {
    return StoryLoaded(
      memories: memories ?? this.memories,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isVaultUnlocked: isVaultUnlocked ?? this.isVaultUnlocked,
    );
  }
}

class StoryError extends StoryState {
  final String message;
  const StoryError(this.message);
}

class MemoryItem {
  final String id;
  final String imageUrl;
  final String title;
  final String note;
  final String dateString; // e.g. "June 22, 2026"
  final DateTime dateTime;
  final String uploadedBy; // "You" or "Bae"
  final bool isMilestone;
  final bool isPrivate;
  final String layoutType; // "full" or "grid"

  const MemoryItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.note,
    required this.dateString,
    required this.dateTime,
    required this.uploadedBy,
    required this.isMilestone,
    required this.isPrivate,
    required this.layoutType,
  });

  MemoryItem copyWith({
    String? id,
    String? imageUrl,
    String? title,
    String? note,
    String? dateString,
    DateTime? dateTime,
    String? uploadedBy,
    bool? isMilestone,
    bool? isPrivate,
    String? layoutType,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      note: note ?? this.note,
      dateString: dateString ?? this.dateString,
      dateTime: dateTime ?? this.dateTime,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      isMilestone: isMilestone ?? this.isMilestone,
      isPrivate: isPrivate ?? this.isPrivate,
      layoutType: layoutType ?? this.layoutType,
    );
  }
}
