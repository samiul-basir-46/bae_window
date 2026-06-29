import 'package:flutter/foundation.dart';

@immutable
abstract class SpaceEvent {
  const SpaceEvent();
}

class LoadSpaceEvent extends SpaceEvent {
  const LoadSpaceEvent();
}

class SendLoveNoteEvent extends SpaceEvent {
  final String note;
  const SendLoveNoteEvent(this.note);
}

class TogglePartnerStatusEvent extends SpaceEvent {
  final bool isOnline;
  const TogglePartnerStatusEvent(this.isOnline);
}
