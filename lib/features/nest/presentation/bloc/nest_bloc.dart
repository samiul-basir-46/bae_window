import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';
import 'nest_event.dart';
import 'nest_state.dart';

class NestBloc extends Bloc<NestEvent, NestState> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  StreamSubscription? _userSubscription;
  StreamSubscription? _partnerSubscription;
  String? _pairId;

  NestBloc() : super(const NestInitial()) {
    on<LoadNestEvent>(_onLoadNest);
    on<ToggleVaultLockEvent>(_onToggleVaultLock);
    on<ToggleFocusModeEvent>(_onToggleFocusMode);
    on<ChangeThemeEvent>(_onChangeTheme);
    on<SwapConnectionAvatarsEvent>(_onSwapConnectionAvatars);
    on<NestUserDataUpdated>(_onUserDataUpdated);
    on<NestPartnerDataUpdated>(_onPartnerDataUpdated);
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
        _pairId = userData?['pairId'] as String?;
        if (_pairId != null) {
          final partnerUid = await _authService.getPartnerUid(_pairId!);
          if (partnerUid != null) {
            final partnerData = await _authService.getUserProfile(partnerUid);
            partnerName = partnerData?['nickname'] as String? ??
                partnerData?['name'] as String? ??
                "Bae";
            partnerAvatarUrl = partnerData?['profilePicture'] as String? ?? "";
            _startPartnerListener(partnerUid);
          }
        }
      } else {
        _pairId = null;
        await _partnerSubscription?.cancel();
        _partnerSubscription = null;
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

      _startUserListener(user.uid);
    } catch (e) {
      emit(NestError(e.toString()));
    }
  }

  void _startUserListener(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _authService.userStream(uid).listen((snapshot) {
      final data = snapshot.data();
      if (snapshot.exists && data != null) {
        add(NestUserDataUpdated(data));
      }
    });
  }

  void _startPartnerListener(String partnerUid) {
    _partnerSubscription?.cancel();
    _partnerSubscription =
        _authService.userStream(partnerUid).listen((snapshot) {
      final data = snapshot.data();
      if (snapshot.exists && data != null) {
        add(NestPartnerDataUpdated(data));
      }
    });
  }

  Future<void> _onUserDataUpdated(
    NestUserDataUpdated event,
    Emitter<NestState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NestLoaded) return;

    final newPairId = event.data['pairId'] as String?;
    final isPaired = event.data['pairStatus'] == 'paired' && newPairId != null;

    String partnerName = currentState.partnerName;
    String partnerAvatarUrl = currentState.partnerAvatarUrl;

    if (!isPaired) {
      _pairId = null;
      await _partnerSubscription?.cancel();
      _partnerSubscription = null;
      partnerName = 'Bae';
      partnerAvatarUrl = '';
    } else if (newPairId != _pairId || _partnerSubscription == null) {
      _pairId = newPairId;
      final partnerUid = await _authService.getPartnerUid(newPairId);
      if (partnerUid != null) {
        final partnerData = await _authService.getUserProfile(partnerUid);
        partnerName = partnerData?['nickname'] as String? ??
            partnerData?['name'] as String? ??
            'Bae';
        partnerAvatarUrl = partnerData?['profilePicture'] as String? ?? '';
        _startPartnerListener(partnerUid);
      }
    }

    emit(currentState.copyWith(
      isPaired: isPaired,
      userAvatarUrl: event.data['profilePicture'] as String? ?? '',
      partnerName: partnerName,
      partnerAvatarUrl: partnerAvatarUrl,
    ));
  }

  void _onPartnerDataUpdated(
    NestPartnerDataUpdated event,
    Emitter<NestState> emit,
  ) {
    final currentState = state;
    if (currentState is! NestLoaded) return;

    emit(currentState.copyWith(
      partnerName: event.data['nickname'] as String? ??
          event.data['name'] as String? ??
          'Bae',
      partnerAvatarUrl: event.data['profilePicture'] as String? ?? '',
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

  void _onSwapConnectionAvatars(
    SwapConnectionAvatarsEvent event,
    Emitter<NestState> emit,
  ) {
    final currentState = state;
    if (currentState is NestLoaded) {
      emit(currentState.copyWith(
        isLeftAvatarOnTop: !currentState.isLeftAvatarOnTop,
      ));
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    _partnerSubscription?.cancel();
    return super.close();
  }
}
