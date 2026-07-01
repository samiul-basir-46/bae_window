import '../models/special_day_model.dart';

abstract class SpecialDayState {
  const SpecialDayState();
}

class SpecialDayInitial extends SpecialDayState {
  const SpecialDayInitial();
}

class SpecialDayLoading extends SpecialDayState {
  const SpecialDayLoading();
}

class SpecialDaysLoaded extends SpecialDayState {
  final List<SpecialDayModel> days;
  const SpecialDaysLoaded(this.days);
}

class SpecialDaySuccess extends SpecialDayState {
  final String message;
  const SpecialDaySuccess(this.message);
}

class SpecialDayFailure extends SpecialDayState {
  final String error;
  const SpecialDayFailure(this.error);
}
