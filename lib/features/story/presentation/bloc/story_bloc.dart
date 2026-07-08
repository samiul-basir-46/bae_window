import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/features/space_screen/services/realtime_sync_service.dart';
import 'package:bea_window_app/features/auth/services/cloudinary_service.dart';
import 'story_event.dart';
import 'story_state.dart';

class StoryBloc extends Bloc<StoryEvent, StoryState> {
  final RealtimeSyncService _syncService = RealtimeSyncService();

  String? _coupleId;
  String? _currentUserUid;
  String? _currentUserName;
  String? _partnerName;

  StoryBloc() : super(const StoryInitial()) {
    on<LoadStoriesEvent>(_onLoadStories);
    on<ChangeFilterEvent>(_onChangeFilter);
    on<AddMemoryEvent>(_onAddMemory);
    on<DeleteMemoryEvent>(_onDeleteMemory);
    on<EditMemoryNoteEvent>(_onEditMemoryNote);
  }

  Future<void> _onLoadStories(
    LoadStoriesEvent event,
    Emitter<StoryState> emit,
  ) async {
    dev.log('[StoryBloc] Loading stories for coupleId=${event.coupleId}, forceRefresh=${event.forceRefresh}', name: 'StoryBloc');
    
    _coupleId = event.coupleId;
    _currentUserUid = event.currentUserUid;
    _currentUserName = event.currentUserName;
    _partnerName = event.partnerName;

    // If we already have stories loaded or uploading and this is not a force refresh,
    // we return instantly to avoid redundant reads!
    if ((state is StoryLoaded || state is StoryUploading) && !event.forceRefresh) {
      dev.log('[StoryBloc] Stories already loaded in state, skipping read operation to save Firestore reads.', name: 'StoryBloc');
      return;
    }

    // Show loading state if we are loading for the first time or doing a force refresh
    emit(const StoryLoading());

    try {
      final docs = await _syncService.getStories(event.coupleId, forceRefresh: event.forceRefresh);
      
      final memories = docs.map((data) {
        final docId = data['id'] as String? ?? '';
        final creatorUid = data['uploadedByUid'] as String? ?? '';
        
        final uploadedBy = (creatorUid == _currentUserUid)
            ? "You"
            : _partnerName ?? "Bae";

        final ts = data['dateTime'] as Timestamp?;
        final dateTime = ts?.toDate() ?? DateTime.now();

        final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        final dateString = "${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}";

        final mainUrl = data['imageUrl'] as String? ?? '';
        final rawImages = data['images'] as List<dynamic>?;
        final images = rawImages != null
            ? rawImages.map((e) => e.toString()).toList()
            : [mainUrl].where((url) => url.isNotEmpty).toList();

        return MemoryItem(
          id: docId,
          imageUrl: mainUrl,
          images: images,
          title: data['title'] as String? ?? '',
          note: data['note'] as String? ?? '',
          dateString: dateString,
          dateTime: dateTime,
          uploadedBy: uploadedBy,
          isMilestone: data['isMilestone'] as bool? ?? false,
          layoutType: data['layoutType'] as String? ?? 'full',
        );
      }).toList();

      final currentFilter = (state is StoryLoaded)
          ? (state as StoryLoaded).selectedFilter
          : ((state is StoryUploading) ? (state as StoryUploading).selectedFilter : StoryFilter.all);

      emit(StoryLoaded(
        memories: memories,
        selectedFilter: currentFilter,
      ));
    } catch (e) {
      dev.log('[StoryBloc] Error loading stories: $e', name: 'StoryBloc');
      emit(StoryError("Failed to load stories: $e"));
    }
  }

  void _onChangeFilter(
    ChangeFilterEvent event,
    Emitter<StoryState> emit,
  ) {
    if (state is StoryLoaded) {
      final loadedState = state as StoryLoaded;
      emit(loadedState.copyWith(selectedFilter: event.filter));
    } else if (state is StoryUploading) {
      final uploadState = state as StoryUploading;
      emit(StoryUploading(
        memories: uploadState.memories,
        selectedFilter: event.filter,
        progressMessage: uploadState.progressMessage,
      ));
    }
  }

  Future<void> _onAddMemory(
    AddMemoryEvent event,
    Emitter<StoryState> emit,
  ) async {
    if (_coupleId == null || _currentUserUid == null) return;

    final List<MemoryItem> currentMemories = (state is StoryLoaded)
        ? (state as StoryLoaded).memories
        : ((state is StoryUploading) ? (state as StoryUploading).memories : []);

    final StoryFilter currentFilter = (state is StoryLoaded)
        ? (state as StoryLoaded).selectedFilter
        : ((state is StoryUploading) ? (state as StoryUploading).selectedFilter : StoryFilter.all);

    try {
      final List<String> images = [];
      String mainImageUrl = "";

      // 1. Emit progress: Uploading primary cover image
      emit(StoryUploading(
        memories: currentMemories,
        selectedFilter: currentFilter,
        progressMessage: "Uploading cover photo... 📸",
      ));

      if (event.imageFile != null) {
        dev.log('[StoryBloc] Uploading primary memory image file to Cloudinary...', name: 'StoryBloc');
        final uploadedUrl = await CloudinaryService.uploadImage(event.imageFile!);
        if (uploadedUrl != null) {
          mainImageUrl = uploadedUrl;
          images.add(uploadedUrl);
        } else {
          throw Exception("Primary image upload failed");
        }
      }

      // 2. Upload additional images and emit progress for each
      for (int i = 0; i < event.additionalImageFiles.length; i++) {
        emit(StoryUploading(
          memories: currentMemories,
          selectedFilter: currentFilter,
          progressMessage: "Uploading photo ${i + 1} of ${event.additionalImageFiles.length}... 🌸",
        ));

        final extraFile = event.additionalImageFiles[i];
        dev.log('[StoryBloc] Uploading additional memory image file to Cloudinary...', name: 'StoryBloc');
        final uploadedUrl = await CloudinaryService.uploadImage(extraFile);
        if (uploadedUrl != null) {
          images.add(uploadedUrl);
        } else {
          dev.log('[StoryBloc] Additional Cloudinary upload failed, skipping', name: 'StoryBloc');
        }
      }

      // 3. Emit progress: Saving to Firestore
      emit(StoryUploading(
        memories: currentMemories,
        selectedFilter: currentFilter,
        progressMessage: "Saving memory lane... 💾",
      ));

      await _syncService.addStory(
        coupleId: _coupleId!,
        title: event.title,
        note: event.note,
        imageUrl: mainImageUrl,
        images: images,
        isMilestone: event.isMilestone,
        uploadedByUid: _currentUserUid!,
        layoutType: event.layoutType,
      );

      // Force refresh feed to display the newly added memory instantly
      add(LoadStoriesEvent(
        coupleId: _coupleId!,
        currentUserUid: _currentUserUid!,
        currentUserName: _currentUserName ?? "You",
        partnerName: _partnerName ?? "Bae",
        forceRefresh: true,
      ));
    } catch (e) {
      dev.log('[StoryBloc] Error adding memory: $e', name: 'StoryBloc');
      emit(StoryLoaded(memories: currentMemories, selectedFilter: currentFilter));
    }
  }

  Future<void> _onDeleteMemory(
    DeleteMemoryEvent event,
    Emitter<StoryState> emit,
  ) async {
    if (_coupleId == null || _currentUserUid == null) return;
    try {
      await _syncService.deleteStory(_coupleId!, event.id);

      // Force refresh feed to instantly reflect changes
      add(LoadStoriesEvent(
        coupleId: _coupleId!,
        currentUserUid: _currentUserUid!,
        currentUserName: _currentUserName ?? "You",
        partnerName: _partnerName ?? "Bae",
        forceRefresh: true,
      ));
    } catch (e) {
      dev.log('[StoryBloc] Error deleting memory: $e', name: 'StoryBloc');
    }
  }

  Future<void> _onEditMemoryNote(
    EditMemoryNoteEvent event,
    Emitter<StoryState> emit,
  ) async {
    if (_coupleId == null || _currentUserUid == null) return;
    try {
      await _syncService.updateStoryNote(
        coupleId: _coupleId!,
        storyId: event.id,
        newNote: event.newNote,
      );

      // Force refresh feed to instantly reflect edits
      add(LoadStoriesEvent(
        coupleId: _coupleId!,
        currentUserUid: _currentUserUid!,
        currentUserName: _currentUserName ?? "You",
        partnerName: _partnerName ?? "Bae",
        forceRefresh: true,
      ));
    } catch (e) {
      dev.log('[StoryBloc] Error updating memory note: $e', name: 'StoryBloc');
    }
  }
}
