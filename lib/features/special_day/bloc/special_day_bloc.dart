import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/special_day_sync_service.dart';
import 'special_day_event.dart';
import 'special_day_state.dart';

class SpecialDayBloc extends Bloc<SpecialDayEvent, SpecialDayState> {
  final SpecialDaySyncService _syncService;
  StreamSubscription? _subscription;

  SpecialDayBloc({SpecialDaySyncService? syncService})
      : _syncService = syncService ?? SpecialDaySyncService(),
        super(const SpecialDayInitial()) {
    on<WatchSpecialDaysEvent>(_onWatchSpecialDays);
    on<SpecialDaysUpdatedEvent>(_onSpecialDaysUpdated);
    on<AddSpecialDayEvent>(_onAddSpecialDay);
    on<UpdateSpecialDayEvent>(_onUpdateSpecialDay);
    on<DeleteSpecialDayEvent>(_onDeleteSpecialDay);
  }

  void _onWatchSpecialDays(
    WatchSpecialDaysEvent event,
    Emitter<SpecialDayState> emit,
  ) {
    _subscription?.cancel();
    _subscription = _syncService.watchSpecialDays(event.coupleId).listen(
      (days) {
        add(SpecialDaysUpdatedEvent(days));
      },
      onError: (e) {
        add(const SpecialDaysUpdatedEvent([]));
      },
    );
  }

  void _onSpecialDaysUpdated(
    SpecialDaysUpdatedEvent event,
    Emitter<SpecialDayState> emit,
  ) {
    emit(SpecialDaysLoaded(event.days));
  }

  Future<void> _onAddSpecialDay(
    AddSpecialDayEvent event,
    Emitter<SpecialDayState> emit,
  ) async {
    emit(const SpecialDayLoading());
    try {
      await _syncService.addSpecialDay(event.coupleId, event.day);
      emit(const SpecialDaySuccess("Special Day added successfully!"));
    } catch (e) {
      emit(SpecialDayFailure("Failed to add special day: $e"));
    }
  }

  Future<void> _onUpdateSpecialDay(
    UpdateSpecialDayEvent event,
    Emitter<SpecialDayState> emit,
  ) async {
    emit(const SpecialDayLoading());
    try {
      await _syncService.updateSpecialDay(event.coupleId, event.day);
      emit(const SpecialDaySuccess("Special Day updated successfully!"));
    } catch (e) {
      emit(SpecialDayFailure("Failed to update special day: $e"));
    }
  }

  Future<void> _onDeleteSpecialDay(
    DeleteSpecialDayEvent event,
    Emitter<SpecialDayState> emit,
  ) async {
    emit(const SpecialDayLoading());
    try {
      await _syncService.deleteSpecialDay(event.coupleId, event.dayId);
      emit(const SpecialDaySuccess("Special Day deleted successfully!"));
    } catch (e) {
      emit(SpecialDayFailure("Failed to delete special day: $e"));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
