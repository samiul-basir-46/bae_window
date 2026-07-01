import 'dart:io';

abstract class HomeActionEvent {
  const HomeActionEvent();
}

enum HomeMediaType { image, drawing, voice }

class ShareHomeMediaRequested extends HomeActionEvent {
  final File file;
  final HomeMediaType mediaType;

  const ShareHomeMediaRequested({
    required this.file,
    required this.mediaType,
  });
}

class SendHomePulseRequested extends HomeActionEvent {
  const SendHomePulseRequested();
}

class UpdateRelationshipDateRequested extends HomeActionEvent {
  final String formattedDate;

  const UpdateRelationshipDateRequested(this.formattedDate);
}
