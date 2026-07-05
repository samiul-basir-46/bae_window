import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bea_window_app/features/chat/bloc/upload_event.dart';
import 'package:bea_window_app/features/chat/bloc/upload_state.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/features/chat/repositories/chat_repository.dart';
import 'package:bea_window_app/helpers/di.dart';

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final ChatRepository _chatRepository = locator<ChatRepository>();

  File? _activeFile;
  ChatMessageType? _activeType;

  List<File>? _activeFiles;
  List<ChatMessageType>? _activeTypes;
  String? _activeConversationId;

  UploadBloc() : super(UploadInitial()) {
    on<StartMediaUploadEvent>(_onStartMediaUpload);
    on<StartMultipleMediaUploadEvent>(_onStartMultipleMediaUpload);
    on<UpdateUploadProgressEvent>(_onUpdateUploadProgress);
    on<CancelUploadEvent>(_onCancelUpload);
    on<RetryUploadEvent>(_onRetryUpload);
  }

  Future<void> _onStartMediaUpload(
    StartMediaUploadEvent event,
    Emitter<UploadState> emit,
  ) async {
    _activeFile = event.file;
    _activeConversationId = event.conversationId;
    _activeType = event.type;
    _activeFiles = null;
    _activeTypes = null;

    emit(UploadingState(progress: 0.0, localFilePath: event.file.path));

    try {
      if (event.type == ChatMessageType.image) {
        final url = await _chatRepository.uploadImage(
          event.file,
          conversationId: event.conversationId,
          onProgress: (p) => add(UpdateUploadProgressEvent(p)),
        );
        emit(UploadSuccess(mediaUrl: url));
      } else if (event.type == ChatMessageType.file) {
        final url = await _chatRepository.uploadFile(
          event.file,
          conversationId: event.conversationId,
          onProgress: (p) => add(UpdateUploadProgressEvent(p)),
        );
        emit(UploadSuccess(mediaUrl: url));
      } else if (event.type == ChatMessageType.video) {
        final urls = await _chatRepository.uploadVideo(
          videoFile: event.file,
          conversationId: event.conversationId,
          onProgress: (p) => add(UpdateUploadProgressEvent(p)),
        );
        emit(UploadSuccess(
          mediaUrl: urls['videoUrl'] ?? '',
          thumbnailUrl: urls['thumbnailUrl'],
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(UploadFailure(e.toString()));
      }
    }
  }

  Future<void> _onStartMultipleMediaUpload(
    StartMultipleMediaUploadEvent event,
    Emitter<UploadState> emit,
  ) async {
    _activeFiles = event.files;
    _activeTypes = event.types;
    _activeConversationId = event.conversationId;
    _activeFile = null;
    _activeType = null;

    final totalCount = event.files.length;
    final List<MediaItemModel> mediaItems = [];
    final List<double> progresses = List.filled(totalCount, 0.0);

    emit(UploadingMultipleState(
      progress: 0.0,
      completedCount: 0,
      totalCount: totalCount,
    ));

    try {
      final uploadTasks = <Future<void>>[];
      for (int i = 0; i < totalCount; i++) {
        final file = event.files[i];
        final type = event.types[i];

        final task = () async {
          String url = '';
          String? thumbnail;

          if (type == ChatMessageType.image) {
            url = await _chatRepository.uploadImage(
              file,
              conversationId: event.conversationId,
              onProgress: (p) {
                progresses[i] = p;
                final overallProgress = progresses.reduce((a, b) => a + b) / totalCount;
                if (!isClosed) {
                  add(UpdateUploadProgressEvent(overallProgress));
                }
              },
            );
          } else if (type == ChatMessageType.video) {
            final urls = await _chatRepository.uploadVideo(
              videoFile: file,
              conversationId: event.conversationId,
              onProgress: (p) {
                progresses[i] = p;
                final overallProgress = progresses.reduce((a, b) => a + b) / totalCount;
                if (!isClosed) {
                  add(UpdateUploadProgressEvent(overallProgress));
                }
              },
            );
            url = urls['videoUrl'] ?? '';
            thumbnail = urls['thumbnailUrl'];
          } else {
            url = await _chatRepository.uploadFile(
              file,
              conversationId: event.conversationId,
              onProgress: (p) {
                progresses[i] = p;
                final overallProgress = progresses.reduce((a, b) => a + b) / totalCount;
                if (!isClosed) {
                  add(UpdateUploadProgressEvent(overallProgress));
                }
              },
            );
          }

          mediaItems.add(MediaItemModel(
            url: url,
            type: type,
            thumbnail: thumbnail,
          ));
        }();
        uploadTasks.add(task);
      }

      await Future.wait(uploadTasks);

      if (!isClosed) {
        emit(UploadMultipleSuccess(mediaItems: mediaItems));
      }
    } catch (e) {
      if (!isClosed) {
        emit(UploadFailure(e.toString()));
      }
    }
  }

  void _onUpdateUploadProgress(
    UpdateUploadProgressEvent event,
    Emitter<UploadState> emit,
  ) {
    if (state is UploadingState) {
      final currentState = state as UploadingState;
      emit(UploadingState(
        progress: event.progress,
        localFilePath: currentState.localFilePath,
      ));
    } else if (state is UploadingMultipleState) {
      final currentState = state as UploadingMultipleState;
      emit(UploadingMultipleState(
        progress: event.progress,
        completedCount: currentState.completedCount,
        totalCount: currentState.totalCount,
      ));
    }
  }

  Future<void> _onCancelUpload(
    CancelUploadEvent event,
    Emitter<UploadState> emit,
  ) async {
    if (_activeFiles != null && _activeTypes != null) {
      for (int i = 0; i < _activeFiles!.length; i++) {
        if (_activeTypes![i] == ChatMessageType.video) {
          try {
            await _chatRepository.cancelVideoUpload(_activeFiles![i].path);
          } catch (_) {}
        }
      }
    } else if (_activeFile != null && _activeType == ChatMessageType.video) {
      try {
        await _chatRepository.cancelVideoUpload(_activeFile!.path);
      } catch (_) {}
    }
    _activeFile = null;
    _activeFiles = null;
    _activeTypes = null;
    _activeType = null;
    _activeConversationId = null;
    emit(UploadInitial());
  }

  void _onRetryUpload(
    RetryUploadEvent event,
    Emitter<UploadState> emit,
  ) {
    if (_activeFiles != null && _activeConversationId != null && _activeTypes != null) {
      add(StartMultipleMediaUploadEvent(
        files: _activeFiles!,
        types: _activeTypes!,
        conversationId: _activeConversationId!,
      ));
    } else if (_activeFile != null && _activeConversationId != null && _activeType != null) {
      add(StartMediaUploadEvent(
        file: _activeFile!,
        conversationId: _activeConversationId!,
        type: _activeType!,
      ));
    }
  }
}
