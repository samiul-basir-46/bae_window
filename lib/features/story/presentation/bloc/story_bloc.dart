import 'package:flutter_bloc/flutter_bloc.dart';
import 'story_event.dart';
import 'story_state.dart';

class StoryBloc extends Bloc<StoryEvent, StoryState> {
  StoryBloc() : super(const StoryInitial()) {
    on<LoadMemoriesEvent>((event, emit) {
      emit(const StoryLoading());
      emit(StoryLoaded(
        memories: _mockMemories,
        selectedFilter: StoryFilter.all,
        isVaultUnlocked: false,
      ));
    });

    on<ChangeFilterEvent>((event, emit) {
      if (state is StoryLoaded) {
        final loadedState = state as StoryLoaded;
        emit(loadedState.copyWith(selectedFilter: event.filter));
      }
    });

    on<AddMemoryEvent>((event, emit) {
      if (state is StoryLoaded) {
        final loadedState = state as StoryLoaded;
        final now = DateTime.now();
        final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        final dateString = "${months[now.month - 1]} ${now.day}, ${now.year}";

        final newItem = MemoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imageUrl: event.imageUrl,
          title: event.title,
          note: event.note,
          dateString: dateString,
          dateTime: now,
          uploadedBy: "You",
          isMilestone: event.isMilestone,
          isPrivate: event.isPrivate,
          layoutType: event.layoutType,
        );

        final updatedMemories = [newItem, ...loadedState.memories];
        emit(loadedState.copyWith(memories: updatedMemories));
      }
    });

    on<UnlockVaultEvent>((event, emit) {
      if (state is StoryLoaded) {
        final loadedState = state as StoryLoaded;
        emit(loadedState.copyWith(isVaultUnlocked: true));
      }
    });

    on<LockVaultEvent>((event, emit) {
      if (state is StoryLoaded) {
        final loadedState = state as StoryLoaded;
        emit(loadedState.copyWith(isVaultUnlocked: false));
      }
    });

    on<DeleteMemoryEvent>((event, emit) {
      if (state is StoryLoaded) {
        final loadedState = state as StoryLoaded;
        final updated = loadedState.memories.where((m) => m.id != event.id).toList();
        emit(loadedState.copyWith(memories: updated));
      }
    });

    on<EditMemoryNoteEvent>((event, emit) {
      if (state is StoryLoaded) {
        final loadedState = state as StoryLoaded;
        final updated = loadedState.memories.map((m) {
          if (m.id == event.id) {
            return m.copyWith(note: event.newNote);
          }
          return m;
        }).toList();
        emit(loadedState.copyWith(memories: updated));
      }
    });

    on<MoveToVaultEvent>((event, emit) {
      if (state is StoryLoaded) {
        final loadedState = state as StoryLoaded;
        final updated = loadedState.memories.map((m) {
          if (m.id == event.id) {
            return m.copyWith(isPrivate: event.isPrivate);
          }
          return m;
        }).toList();
        emit(loadedState.copyWith(memories: updated));
      }
    });
  }

  static final List<MemoryItem> _mockMemories = [
    MemoryItem(
      id: "1",
      imageUrl: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&q=80&w=500",
      title: "Sunset from the rooftop",
      note: "Sunset from the rooftop — our spot forever",
      dateString: "June 22, 2026",
      dateTime: DateTime(2026, 6, 22),
      uploadedBy: "You",
      isMilestone: false,
      isPrivate: false,
      layoutType: "full",
    ),
    MemoryItem(
      id: "2",
      imageUrl: "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&q=80&w=300",
      title: "Morning coffee ritual",
      note: "Morning coffee ritual",
      dateString: "June 18, 2026",
      dateTime: DateTime(2026, 6, 18),
      uploadedBy: "You",
      isMilestone: false,
      isPrivate: false,
      layoutType: "grid",
    ),
    MemoryItem(
      id: "3",
      imageUrl: "https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?auto=format&fit=crop&q=80&w=300",
      title: "Rainy day walks",
      note: "Rainy day walks",
      dateString: "June 15, 2026",
      dateTime: DateTime(2026, 6, 15),
      uploadedBy: "You",
      isMilestone: false,
      isPrivate: false,
      layoutType: "grid",
    ),
    MemoryItem(
      id: "4",
      imageUrl: "https://images.unsplash.com/photo-1513151233558-d860c5398176?auto=format&fit=crop&q=80&w=500",
      title: "3rd Anniversary",
      note: "Happy 3rd anniversary my love ❤️",
      dateString: "Feb 14, 2026",
      dateTime: DateTime(2026, 2, 14),
      uploadedBy: "Bae",
      isMilestone: true,
      isPrivate: false,
      layoutType: "full",
    ),
    MemoryItem(
      id: "5",
      imageUrl: "https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&q=80&w=500",
      title: "First Christmas together",
      note: "First Christmas together",
      dateString: "Dec 25, 2025",
      dateTime: DateTime(2025, 12, 25),
      uploadedBy: "You",
      isMilestone: false,
      isPrivate: true,
      layoutType: "full",
    ),
    MemoryItem(
      id: "6",
      imageUrl: "https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&q=80&w=300",
      title: "Beach day",
      note: "Beach day",
      dateString: "Dec 10, 2025",
      dateTime: DateTime(2025, 12, 10),
      uploadedBy: "You",
      isMilestone: false,
      isPrivate: false,
      layoutType: "grid",
    ),
    MemoryItem(
      id: "7",
      imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&q=80&w=300",
      title: "Late night pizza",
      note: "Late night pizza",
      dateString: "Dec 3, 2025",
      dateTime: DateTime(2025, 12, 3),
      uploadedBy: "You",
      isMilestone: false,
      isPrivate: false,
      layoutType: "grid",
    ),
  ];
}
