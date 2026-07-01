import '../models/special_day_model.dart';

abstract class SpecialDayEvent {
  const SpecialDayEvent();
}

class WatchSpecialDaysEvent extends SpecialDayEvent {
  final String coupleId;
  const WatchSpecialDaysEvent(this.coupleId);
}

class SpecialDaysUpdatedEvent extends SpecialDayEvent {
  final List<SpecialDayModel> days;
  const SpecialDaysUpdatedEvent(this.days);
}

class AddSpecialDayEvent extends SpecialDayEvent {
  final String coupleId;
  final SpecialDayModel day;
  const AddSpecialDayEvent({required this.coupleId, required this.day});
}

class UpdateSpecialDayEvent extends SpecialDayEvent {
  final String coupleId;
  final SpecialDayModel day;
  const UpdateSpecialDayEvent({required this.coupleId, required this.day});
}

class DeleteSpecialDayEvent extends SpecialDayEvent {
  final String coupleId;
  final String dayId;
  const DeleteSpecialDayEvent({required this.coupleId, required this.dayId});
}
