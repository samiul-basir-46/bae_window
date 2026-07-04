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
  String? _activeConversationId;
  ChatMessageType? _activeType;

  UploadBloc() : super(UploadInitial()) {
    on<StartMediaUploadEvent>(_onStartMediaUpload);
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
    }
  }

  Future<void> _onCancelUpload(
    CancelUploadEvent event,
    Emitter<UploadState> emit,
  ) async {
    if (_activeFile != null && _activeType == ChatMessageType.video) {
      try {
        await _chatRepository.cancelVideoUpload(_activeFile!.path);
      } catch (_) {}
    }
    _activeFile = null;
    _activeConversationId = null;
    _activeType = null;
    emit(UploadInitial());
  }

  void _onRetryUpload(
    RetryUploadEvent event,
    Emitter<UploadState> emit,
  ) {
    if (_activeFile != null && _activeConversationId != null && _activeType != null) {
      add(StartMediaUploadEvent(
        file: _activeFile!,
        conversationId: _activeConversationId!,
        type: _activeType!,
      ));
    }
  }
}
