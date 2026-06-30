import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';
import 'nest_event.dart';
import 'nest_state.dart';

class NestBloc extends Bloc<NestEvent, NestState> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  NestBloc() : super(const NestInitial()) {
    on<LoadNestEvent>(_onLoadNest);
    on<ToggleVaultLockEvent>(_onToggleVaultLock);
    on<ToggleFocusModeEvent>(_onToggleFocusMode);
    on<ChangeThemeEvent>(_onChangeTheme);
    on<SwapConnectionAvatarsEvent>(_onSwapConnectionAvatars);
  }

  Future<void> _onLoadNest(LoadNestEvent event, Emitter<NestState> emit) async {
    emit(const NestLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(const NestError('User not logged in'));
        return;
      }

      final userData = await _authService.getUserProfile(user.uid);
      final isPaired = (userData?['pairStatus'] == 'paired');
      final userAvatarUrl = userData?['profilePicture'] as String? ?? '';

      String partnerName = "Bae";
      String partnerAvatarUrl = "";
      if (isPaired) {
        final pairId = userData?['pairId'] as String?;
        if (pairId != null) {
          final partnerUid = await _authService.getPartnerUid(pairId);
          if (partnerUid != null) {
            final partnerData = await _authService.getUserProfile(partnerUid);
            partnerName = partnerData?['nickname'] as String? ?? partnerData?['name'] as String? ?? "Bae";
            partnerAvatarUrl = partnerData?['profilePicture'] as String? ?? "";
          }
        }
      }

      emit(NestLoaded(
        isVaultLocked: true,
        isFocusMode: false,
        selectedTheme: "Dark",
        partnerName: partnerName,
        isLeftAvatarOnTop: true,
        isPaired: isPaired,
        userAvatarUrl: userAvatarUrl,
        partnerAvatarUrl: partnerAvatarUrl,
      ));
    } catch (e) {
      emit(NestError(e.toString()));
    }
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
