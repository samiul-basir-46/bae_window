import 'package:bea_window_app/features/chat/models/message_model.dart';

abstract class UploadState {
  const UploadState();
}

class UploadInitial extends UploadState {}

class UploadingState extends UploadState {
  final double progress; // 0.0 to 1.0
  final String localFilePath;
  const UploadingState({required this.progress, required this.localFilePath});
}

class UploadSuccess extends UploadState {
  final String mediaUrl;
  final String? thumbnailUrl;
  const UploadSuccess({required this.mediaUrl, this.thumbnailUrl});
}

class UploadMultipleSuccess extends UploadState {
  final List<MediaItemModel> mediaItems;
  const UploadMultipleSuccess({required this.mediaItems});
}

class UploadingMultipleState extends UploadState {
  final double progress; // Overall progress
  final int completedCount;
  final int totalCount;
  const UploadingMultipleState({
    required this.progress,
    required this.completedCount,
    required this.totalCount,
  });
}

class UploadFailure extends UploadState {
  final String error;
  const UploadFailure(this.error);
}
