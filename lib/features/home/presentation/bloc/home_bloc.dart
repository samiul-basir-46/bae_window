import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';
import 'package:intl/intl.dart';
import 'home_event.dart';
import 'home_state.dart';
import 'package:bea_window_app/helpers/widget_helper.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  StreamSubscription? _userSub;
  StreamSubscription? _partnerSub;

  // Cache the latest data for merging user + partner updates
  Map<String, dynamic>? _cachedUserData;
  Map<String, dynamic>? _cachedPartnerData;
  String? _partnerUid;
  bool _isPaired = false;

  HomeBloc() : super(const HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<UpdateUserMoodEvent>(_onUpdateUserMood);
    on<UpdateAwarenessEvent>(_onUpdateAwareness);
    on<UserDataUpdated>(_onUserDataUpdated);
    on<PartnerDataUpdated>(_onPartnerDataUpdated);
  }

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(const HomeError('No authenticated user found.'));
      return;
    }

    dev.log('HomeBloc: Loading home data for ${user.uid}', name: 'HomeBloc');

    try {
      // Get user's own profile first
      final userData = await _authService.getUserProfile(user.uid);
      if (userData == null) {
        emit(const HomeError('User profile not found.'));
        return;
      }

      _cachedUserData = userData;
      final pairStatus = userData['pairStatus'] as String? ?? 'none';
      final pairId = userData['pairId'] as String?;
      _isPaired = pairStatus == 'paired' && pairId != null;

      // If paired, get partner UID and start listening
      if (_isPaired && pairId != null) {
        dev.log('HomeBloc: User is paired (coupleId: $pairId). Resolving partner...',
            name: 'HomeBloc');
        _partnerUid = await _authService.getPartnerUid(pairId);
        if (_partnerUid != null) {
          dev.log('HomeBloc: Partner UID resolved: $_partnerUid', name: 'HomeBloc');
          // Get partner data once to emit initial state
          _cachedPartnerData = await _authService.getUserProfile(_partnerUid!);
        }
      } else {
        dev.log('HomeBloc: User is unpaired (status: $pairStatus)', name: 'HomeBloc');
      }

      // Emit initial loaded state
      _emitLoadedState(emit);

      // Start real-time listeners
      _startUserListener(user.uid);
      if (_partnerUid != null) {
        _startPartnerListener(_partnerUid!);
      }
    } catch (e, stack) {
      dev.log('HomeBloc: Error loading home data: $e',
          error: e, stackTrace: stack, name: 'HomeBloc');
      emit(HomeError('Failed to load home data: $e'));
    }
  }

  void _startUserListener(String uid) {
    _userSub?.cancel();
    _userSub = _authService.userStream(uid).listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          add(UserDataUpdated(snapshot.data()!));
        }
      },
      onError: (e) {
        dev.log('HomeBloc: User stream error: $e', name: 'HomeBloc');
      },
    );
  }

  void _startPartnerListener(String partnerUid) {
    _partnerSub?.cancel();
    _partnerSub = _authService.userStream(partnerUid).listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          add(PartnerDataUpdated(snapshot.data()!));
        }
      },
      onError: (e) {
        dev.log('HomeBloc: Partner stream error: $e', name: 'HomeBloc');
      },
    );
  }

  void _onUserDataUpdated(
    UserDataUpdated event,
    Emitter<HomeState> emit,
  ) {
    _cachedUserData = event.data;

    // Check if pairing status changed (e.g. partner just joined)
    final newPairStatus = event.data['pairStatus'] as String? ?? 'none';
    final newPairId = event.data['pairId'] as String?;
    final wasPaired = _isPaired;
    _isPaired = newPairStatus == 'paired' && newPairId != null;

    // If just became paired, start partner listener
    if (_isPaired && !wasPaired && newPairId != null) {
      dev.log('HomeBloc: Pairing detected in real-time! Resolving partner...',
          name: 'HomeBloc');
      _resolveAndListenPartner(newPairId);
    }

    _emitLoadedState(emit);
  }

  Future<void> _resolveAndListenPartner(String pairId) async {
    _partnerUid = await _authService.getPartnerUid(pairId);
    if (_partnerUid != null) {
      _cachedPartnerData = await _authService.getUserProfile(_partnerUid!);
      _startPartnerListener(_partnerUid!);
    }
  }

  void _onPartnerDataUpdated(
    PartnerDataUpdated event,
    Emitter<HomeState> emit,
  ) {
    _cachedPartnerData = event.data;
    _emitLoadedState(emit);
  }

  void _onUpdateUserMood(
    UpdateUserMoodEvent event,
    Emitter<HomeState> emit,
  ) {
    // Write mood to Firestore (fire-and-forget — partner sees via stream)
    _authService.updateMood(emoji: event.emoji, text: event.text);

    // Optimistic local update
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(
        userMoodEmoji: event.emoji,
        userMoodText: event.text,
      ));
    }
  }

  void _onUpdateAwareness(
    UpdateAwarenessEvent event,
    Emitter<HomeState> emit,
  ) {
    if (state is HomeLoaded) {
      emit((state as HomeLoaded).copyWith(
        awarenessMessage: event.message,
        awarenessIcon: event.icon,
      ));
    }
  }

  void _emitLoadedState(Emitter<HomeState> emit) {
    final userData = _cachedUserData;
    if (userData == null) return;

    // Extract user mood
    final moodData = userData['mood'] as Map<String, dynamic>?;
    final userMoodEmoji = moodData?['emoji'] as String? ?? '😊';
    final userMoodText = moodData?['text'] as String? ?? 'Happy';

    // Extract user info
    final userAvatar = userData['profilePicture'] as String? ?? '';
    final userName = userData['nickname'] as String? ??
        userData['name'] as String? ??
        'You';
    final inviteCode = userData['inviteCode'] as String?;

    // Extract partner info (if paired)
    String? partnerAvatar;
    String? partnerName;
    String? partnerMoodEmoji;
    String? partnerMoodText;
    int? daysTogether;

    if (_isPaired && _cachedPartnerData != null) {
      final partnerData = _cachedPartnerData!;
      partnerAvatar = partnerData['profilePicture'] as String? ?? '';
      partnerName = partnerData['nickname'] as String? ??
          partnerData['name'] as String? ??
          'Partner';

      final partnerMood = partnerData['mood'] as Map<String, dynamic>?;
      partnerMoodEmoji = partnerMood?['emoji'] as String?;
      partnerMoodText = partnerMood?['text'] as String?;

      // Calculate days together from relationshipStartDate (checks both own and partner's profile)
      daysTogether = _calculateDaysTogether(userData) ?? _calculateDaysTogether(partnerData);
    }

    emit(HomeLoaded(
      isPaired: _isPaired,
      userAvatarUrl: userAvatar,
      userMoodEmoji: userMoodEmoji,
      userMoodText: userMoodText,
      userName: userName,
      partnerAvatarUrl: partnerAvatar,
      partnerName: partnerName,
      isPartnerOnline: _isPaired, // placeholder — true when paired
      daysTogether: daysTogether,
      partnerMoodEmoji: partnerMoodEmoji,
      partnerMoodText: partnerMoodText,
      inviteCode: inviteCode,
      // Keep placeholder data for widgets not yet integrated
      livePeekImageUrl: '',
      relationshipPulse: _isPaired
          ? const [
              PulseData(day: "M", userCount: 4, partnerCount: 6),
              PulseData(day: "T", userCount: 6, partnerCount: 4),
              PulseData(day: "W", userCount: 3, partnerCount: 5),
              PulseData(day: "T", userCount: 7, partnerCount: 5),
              PulseData(day: "F", userCount: 5, partnerCount: 8),
              PulseData(day: "S", userCount: 8, partnerCount: 4),
              PulseData(day: "S", userCount: 4, partnerCount: 7),
            ]
          : const [],
      questionOfTheDay: _isPaired
          ? const TriviaQuestion(
              questionText:
                  "আমাদের প্রথম ডেটের কোন মুহূর্তটি তোমার সবচেয়ে প্রিয়?",
              isAnswered: false,
            )
          : null,
      checkInLogs: const [],
      nextSpecialDay: daysTogether != null
          ? SpecialDay(
              title: "Next Milestone",
              targetDate: DateTime.now().add(const Duration(days: 30)),
            )
          : null,
    ));

    // Update Home Screen Widget in background
    WidgetHelper.updateWidget(
      isPaired: _isPaired,
      partnerName: partnerName,
      daysTogether: daysTogether,
      latestSnapUrl: '', // Will connect to actual snap image URL field once available
    );
  }

  int? _calculateDaysTogether(Map<String, dynamic> userData) {
    final dateStr = userData['relationshipStartDate'] as String?;
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // Try parsing "MMM d, yyyy" format (e.g. "Jun 15, 2024")
      final date = DateFormat('MMM d, yyyy').parse(dateStr);
      return DateTime.now().difference(date).inDays;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() {
    _userSub?.cancel();
    _partnerSub?.cancel();
    return super.close();
  }
}
