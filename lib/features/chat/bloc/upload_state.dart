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

class UploadFailure extends UploadState {
  final String error;
  const UploadFailure(this.error);
}
