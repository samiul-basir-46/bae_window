import 'package:flutter/foundation.dart';
import '../models/bucket_list_model.dart';

@immutable
abstract class SpaceScreenEvent {
  const SpaceScreenEvent();
}

class LoadSpaceScreenDataEvent extends SpaceScreenEvent {
  const LoadSpaceScreenDataEvent();
}

class BucketListUpdatedEvent extends SpaceScreenEvent {
  final List<BucketListItem> items;
  const BucketListUpdatedEvent(this.items);
}

class AnniversaryUpdatedEvent extends SpaceScreenEvent {
  final DateTime? date;
  const AnniversaryUpdatedEvent(this.date);
}

class PartnerNicknameUpdatedEvent extends SpaceScreenEvent {
  final String? nickname;
  const PartnerNicknameUpdatedEvent(this.nickname);
}

class PartnerPresenceUpdatedEvent extends SpaceScreenEvent {
  final bool isOnline;
  const PartnerPresenceUpdatedEvent(this.isOnline);
}

class AddBucketItemEvent extends SpaceScreenEvent {
  final BucketListItem item;
  const AddBucketItemEvent(this.item);
}

class UpdateBucketItemEvent extends SpaceScreenEvent {
  final BucketListItem item;
  const UpdateBucketItemEvent(this.item);
}

class DeleteBucketItemEvent extends SpaceScreenEvent {
  final String itemId;
  const DeleteBucketItemEvent(this.itemId);
}

class UpdateAnniversaryEvent extends SpaceScreenEvent {
  final DateTime date;
  const UpdateAnniversaryEvent(this.date);
}

class SendSpaceLoveNoteEvent extends SpaceScreenEvent {
  final String note;
  const SendSpaceLoveNoteEvent(this.note);
}

class TasksUpdatedEvent extends SpaceScreenEvent {
  final List<Map<String, dynamic>> tasks;
  const TasksUpdatedEvent(this.tasks);
}

class MomentsUpdatedEvent extends SpaceScreenEvent {
  final List<Map<String, dynamic>> moments;
  const MomentsUpdatedEvent(this.moments);
}
