import 'package:flutter_bloc/flutter_bloc.dart';
import 'nest_event.dart';
import 'nest_state.dart';

class NestBloc extends Bloc<NestEvent, NestState> {
  NestBloc() : super(const NestInitial()) {
    on<LoadNestEvent>(_onLoadNest);
    on<ToggleVaultLockEvent>(_onToggleVaultLock);
    on<ToggleFocusModeEvent>(_onToggleFocusMode);
    on<ChangeThemeEvent>(_onChangeTheme);
    on<SwapConnectionAvatarsEvent>(_onSwapConnectionAvatars);
  }

  void _onLoadNest(LoadNestEvent event, Emitter<NestState> emit) {
    emit(const NestLoading());
    emit(const NestLoaded(
      isVaultLocked: true,
      isFocusMode: false,
      selectedTheme: "Dark",
      partnerName: "Bae",
      isLeftAvatarOnTop: true,
    ));
  }

  void _onToggleVaultLock(ToggleVaultLockEvent event, Emitter<NestState> emit) {
    final currentState = state;
    if (currentState is NestLoaded) {
      emit(currentState.copyWith(isVaultLocked: event.isLocked));
    }
  }

  void _onToggleFocusMode(ToggleFocusModeEvent event, Emitter<NestState> emit) {
    final currentState = state;
    if (currentState is NestLoaded) {
      emit(currentState.copyWith(isFocusMode: event.isFocus));
    }
  }

  void _onChangeTheme(ChangeThemeEvent event, Emitter<NestState> emit) {
    final currentState = state;
    if (currentState is NestLoaded) {
      emit(currentState.copyWith(selectedTheme: event.theme));
    }
  }

  void _onSwapConnectionAvatars(SwapConnectionAvatarsEvent event, Emitter<NestState> emit) {
    final currentState = state;
    if (currentState is NestLoaded) {
      emit(currentState.copyWith(isLeftAvatarOnTop: !currentState.isLeftAvatarOnTop));
    }
  }
}
