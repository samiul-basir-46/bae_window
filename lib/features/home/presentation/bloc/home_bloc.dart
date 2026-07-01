import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';
import 'package:intl/intl.dart';
import 'home_event.dart';
import 'home_state.dart';
import 'package:bea_window_app/helpers/widget_helper.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  static const MethodChannel _pulseChannel = MethodChannel('bea_window/pulse');
  static const MethodChannel _deviceChannel =
      MethodChannel('bea_window/device');

  final FirebaseAuthService _authService = FirebaseAuthService();

  StreamSubscription? _userSub;
  StreamSubscription? _partnerSub;
  StreamSubscription? _coupleSub;
  Timer? _batteryTimer;

  // Cache the latest data for merging user + partner updates
  Map<String, dynamic>? _cachedUserData;
  Map<String, dynamic>? _cachedPartnerData;
  Map<String, dynamic>? _cachedCoupleData;
  String? _currentUserUid;
  String? _partnerUid;
  String? _pairId;
  bool _isPaired = false;
  String _latestPartnerImageUrl = '';
  String _latestPartnerDrawingUrl = '';
  String _latestPartnerVoiceUrl = '';
  bool _partnerPulseSeeded = false;
  String? _lastPartnerPulseId;
  int _partnerPulseTrackingStartedAtMs =
      DateTime.now().toUtc().millisecondsSinceEpoch;

  HomeBloc() : super(const HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<UpdateUserMoodEvent>(_onUpdateUserMood);
    on<UpdateAwarenessEvent>(_onUpdateAwareness);
    on<UserDataUpdated>(_onUserDataUpdated);
    on<PartnerDataUpdated>(_onPartnerDataUpdated);
    on<CoupleDataUpdated>(_onCoupleDataUpdated);
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
      _currentUserUid = user.uid;
      final pairStatus = userData['pairStatus'] as String? ?? 'none';
      final pairId = userData['pairId'] as String?;
      _isPaired = pairStatus == 'paired' && pairId != null;
      _pairId = _isPaired ? pairId : null;
      _cachedCoupleData = null;
      _clearPartnerContentCache();

      // If paired, get partner UID and start listening
      if (_isPaired && pairId != null) {
        dev.log(
            'HomeBloc: User is paired (coupleId: $pairId). Resolving partner...',
            name: 'HomeBloc');
        _partnerUid = await _authService.getPartnerUid(pairId);
        _cachedCoupleData = await _authService.getCoupleData(pairId);
        if (_partnerUid != null) {
          dev.log('HomeBloc: Partner UID resolved: $_partnerUid',
              name: 'HomeBloc');
          // Get partner data once to emit initial state
          _cachedPartnerData = await _authService.getUserProfile(_partnerUid!);
        }
      } else {
        dev.log('HomeBloc: User is unpaired (status: $pairStatus)',
            name: 'HomeBloc');
      }

      // Emit initial loaded state
      await _emitLoadedState(emit);

      // Start real-time listeners
      _startUserListener(user.uid);
      if (_partnerUid != null) {
        _startPartnerListener(_partnerUid!);
      }
      if (_pairId != null) {
        _startCoupleListener(_pairId!);
      }
      _startBatterySync();
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

  void _startCoupleListener(String pairId) {
    _coupleSub?.cancel();
    _coupleSub = _authService.coupleStream(pairId).listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          add(CoupleDataUpdated(snapshot.data()!));
        }
      },
      onError: (e) {
        dev.log('HomeBloc: Couple stream error: $e', name: 'HomeBloc');
      },
    );
  }

  void _startBatterySync() {
    _batteryTimer?.cancel();
    unawaited(_syncBatteryLevel());
    _batteryTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(_syncBatteryLevel()),
    );
  }

  Future<void> _syncBatteryLevel() async {
    try {
      final level = await _deviceChannel.invokeMethod<int>('getBatteryLevel');
      if (level != null) {
        await _authService.updateBatteryLevel(level);
      }
    } catch (e) {
      dev.log('HomeBloc: Battery sync unavailable: $e', name: 'HomeBloc');
    }
  }

  Future<void> _onUserDataUpdated(
    UserDataUpdated event,
    Emitter<HomeState> emit,
  ) async {
    _cachedUserData = event.data;

    // Check if pairing status changed (e.g. partner just joined)
    final newPairStatus = event.data['pairStatus'] as String? ?? 'none';
    final newPairId = event.data['pairId'] as String?;
    final shouldBePaired = newPairStatus == 'paired' && newPairId != null;

    if (shouldBePaired && newPairId != _pairId) {
      dev.log('HomeBloc: Pairing detected in real-time! Resolving partner...',
          name: 'HomeBloc');
      _isPaired = true;
      _pairId = newPairId;
      await _resolveAndListenPartner(newPairId);
    } else if (!shouldBePaired && _isPaired) {
      _isPaired = false;
      _pairId = null;
      _partnerUid = null;
      _cachedPartnerData = null;
      _cachedCoupleData = null;
      await _partnerSub?.cancel();
      _partnerSub = null;
      await _coupleSub?.cancel();
      _coupleSub = null;
      _clearPartnerContentCache();
    } else {
      _isPaired = shouldBePaired;
    }

    await _emitLoadedState(emit);
  }

  Future<void> _resolveAndListenPartner(String pairId) async {
    _cachedCoupleData = await _authService.getCoupleData(pairId);
    _startCoupleListener(pairId);
    final resolvedPartnerUid = await _authService.getPartnerUid(pairId);
    if (resolvedPartnerUid != _partnerUid) {
      _clearPartnerContentCache();
    }
    _partnerUid = resolvedPartnerUid;
    if (_partnerUid != null) {
      _cachedPartnerData = await _authService.getUserProfile(_partnerUid!);
      _startPartnerListener(_partnerUid!);
    } else {
      _cachedPartnerData = null;
      await _partnerSub?.cancel();
      _partnerSub = null;
    }
  }

  Future<void> _onPartnerDataUpdated(
    PartnerDataUpdated event,
    Emitter<HomeState> emit,
  ) async {
    _cachedPartnerData = event.data;
    await _emitLoadedState(emit);
  }

  Future<void> _onCoupleDataUpdated(
    CoupleDataUpdated event,
    Emitter<HomeState> emit,
  ) async {
    _cachedCoupleData = event.data;
    await _emitLoadedState(emit);
  }

  void _onUpdateUserMood(
    UpdateUserMoodEvent event,
    Emitter<HomeState> emit,
  ) {
    // Write mood to Firestore (fire-and-forget — partner sees via stream)
    unawaited(_authService.updateMood(emoji: event.emoji, text: event.text));

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

  void _clearPartnerContentCache() {
    _latestPartnerImageUrl = '';
    _latestPartnerDrawingUrl = '';
    _latestPartnerVoiceUrl = '';
    _partnerPulseSeeded = false;
    _lastPartnerPulseId = null;
    _partnerPulseTrackingStartedAtMs =
        DateTime.now().toUtc().millisecondsSinceEpoch;
  }

  void _handlePartnerPulse(Map<String, dynamic> partnerData) {
    final pulseData = partnerData['latestPulse'];
    final pulseId = pulseData is Map ? pulseData['id']?.toString() : null;
    final sentAt = pulseData is Map ? pulseData['sentAt'] : null;
    final sentAtMs = sentAt is Timestamp
        ? sentAt.toDate().toUtc().millisecondsSinceEpoch
        : pulseData is Map && pulseData['sentAtClientMs'] is num
            ? (pulseData['sentAtClientMs'] as num).toInt()
            : null;

    if (!_partnerPulseSeeded) {
      _partnerPulseSeeded = true;
      _lastPartnerPulseId = pulseId;
      final isFreshPulse = sentAtMs != null &&
          sentAtMs >= _partnerPulseTrackingStartedAtMs - 5000;
      if (pulseId != null && isFreshPulse) {
        unawaited(_vibrateForPartnerPulse());
      }
      return;
    }

    if (pulseId == null || pulseId == _lastPartnerPulseId) return;
    _lastPartnerPulseId = pulseId;
    unawaited(_vibrateForPartnerPulse());
  }

  Future<void> _vibrateForPartnerPulse() async {
    try {
      await _pulseChannel.invokeMethod<void>('vibratePulse');
    } catch (_) {
      await HapticFeedback.vibrate();
      await Future<void>.delayed(const Duration(milliseconds: 140));
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> _emitLoadedState(Emitter<HomeState> emit) async {
    final userData = _cachedUserData;
    if (userData == null) return;

    final moodData = userData['mood'] as Map<String, dynamic>?;
    final userMoodEmoji = moodData?['emoji'] as String? ?? '😊';
    final userMoodText = moodData?['text'] as String? ?? 'Happy';

    final userAvatar = userData['profilePicture'] as String? ?? '';
    final userName =
        userData['nickname'] as String? ?? userData['name'] as String? ?? 'You';
    final inviteCode = userData['inviteCode'] as String?;

    // Extract partner info (if paired)
    String? partnerAvatar;
    String? partnerName;
    String? partnerMoodEmoji;
    String? partnerMoodText;
    int? partnerBatteryLevel;
    int? daysTogether;
    String latestSnapUrl = '';
    String latestImageUrl = '';
    String latestDrawingUrl = '';
    String latestVoiceUrl = '';
    String? latestSnapType;
    List<PulseData> relationshipPulse = const [];

    if (_isPaired && _cachedPartnerData != null) {
      final partnerData = _cachedPartnerData!;
      _handlePartnerPulse(partnerData);
      partnerAvatar = partnerData['profilePicture'] as String? ?? '';
      partnerName = partnerData['nickname'] as String? ??
          partnerData['name'] as String? ??
          'Partner';

      final partnerMood = partnerData['mood'] as Map<String, dynamic>?;
      partnerMoodEmoji = partnerMood?['emoji'] as String?;
      partnerMoodText = partnerMood?['text'] as String?;
      final rawPartnerBattery = partnerData['batteryLevel'];
      partnerBatteryLevel = rawPartnerBattery is num
          ? rawPartnerBattery.toInt().clamp(0, 100).toInt()
          : null;

      // Read snap details sent by partner
      latestSnapUrl = partnerData['latestSnapUrl'] as String? ?? '';
      latestSnapType = partnerData['latestSnapType'] as String?;
      final normalizedType = latestSnapType?.toLowerCase();

      // Separate URLs keep one content type from replacing another. The
      // legacy fallback preserves the most recently shared pre-migration item.
      final directImageUrl = partnerData['latestImageUrl'] as String? ?? '';
      final directDrawingUrl = partnerData['latestDrawingUrl'] as String? ?? '';
      final directVoiceUrl = partnerData['latestVoiceUrl'] as String? ?? '';

      if (directImageUrl.isNotEmpty) {
        _latestPartnerImageUrl = directImageUrl;
      } else if (normalizedType != 'draw' &&
          normalizedType != 'voice' &&
          latestSnapUrl.isNotEmpty) {
        _latestPartnerImageUrl = latestSnapUrl;
      }
      if (directDrawingUrl.isNotEmpty) {
        _latestPartnerDrawingUrl = directDrawingUrl;
      } else if (normalizedType == 'draw' && latestSnapUrl.isNotEmpty) {
        _latestPartnerDrawingUrl = latestSnapUrl;
      }
      if (directVoiceUrl.isNotEmpty) {
        _latestPartnerVoiceUrl = directVoiceUrl;
      } else if (normalizedType == 'voice' && latestSnapUrl.isNotEmpty) {
        _latestPartnerVoiceUrl = latestSnapUrl;
      }

      latestImageUrl = _latestPartnerImageUrl;
      latestDrawingUrl = _latestPartnerDrawingUrl;
      latestVoiceUrl = _latestPartnerVoiceUrl;

      // Calculate days together from relationshipStartDate (checks both own and partner's profile)
      daysTogether = _calculateDaysTogether(userData) ??
          _calculateDaysTogether(partnerData);
      relationshipPulse = _buildWeeklyEngagement(
        userData,
        partnerData,
        coupleData: _cachedCoupleData,
        userUid: _currentUserUid,
        partnerUid: _partnerUid,
      );
    }

    emit(HomeLoaded(
      isPaired: _isPaired,
      userAvatarUrl: userAvatar,
      userMoodEmoji: userMoodEmoji,
      userMoodText: userMoodText,
      userName: userName,
      partnerAvatarUrl: partnerAvatar,
      partnerName: partnerName,
      isPartnerOnline: _isPaired,
      daysTogether: daysTogether,
      partnerMoodEmoji: partnerMoodEmoji,
      partnerMoodText: partnerMoodText,
      inviteCode: inviteCode,
      livePeekImageUrl: latestImageUrl,
      livePeekDrawingUrl: latestDrawingUrl,
      livePeekVoiceUrl: latestVoiceUrl,
      latestSnapType: latestSnapType,
      relationshipPulse: relationshipPulse,
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
    try {
      dev.log(
          'HomeBloc: Calling WidgetHelper.updateWidget(isPaired=$_isPaired, partner=$partnerName, days=$daysTogether, snap=$latestSnapUrl)',
          name: 'HomeBloc');
      await WidgetHelper.updateWidget(
        isPaired: _isPaired,
        partnerName: partnerName,
        daysTogether: daysTogether,
        latestSnapUrl: latestSnapUrl,
        latestSnapType: latestSnapType,
        latestImageUrl: latestImageUrl,
        latestDrawingUrl: latestDrawingUrl,
        latestVoiceUrl: latestVoiceUrl,
        partnerMoodEmoji: partnerMoodEmoji,
        partnerMoodText: partnerMoodText,
        partnerBatteryLevel: partnerBatteryLevel,
      );
      dev.log('HomeBloc: WidgetHelper.updateWidget completed successfully',
          name: 'HomeBloc');
    } catch (e, stack) {
      dev.log('HomeBloc: WidgetHelper.updateWidget FAILED: $e',
          error: e, stackTrace: stack, name: 'HomeBloc');
    }
  }

  int? _calculateDaysTogether(Map<String, dynamic> userData) {
    final dateStr = userData['relationshipStartDate'] as String?;
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      final date = DateFormat('MMM d, yyyy').parse(dateStr);
      return DateTime.now().difference(date).inDays;
    } catch (_) {
      return null;
    }
  }

  List<PulseData> _buildWeeklyEngagement(
    Map<String, dynamic> userData,
    Map<String, dynamic> partnerData, {
    required Map<String, dynamic>? coupleData,
    required String? userUid,
    required String? partnerUid,
  }) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final monday =
        startOfToday.subtract(Duration(days: startOfToday.weekday - 1));
    final sharedEngagement = coupleData?['weeklyEngagement'];
    final sharedUserEngagement = sharedEngagement is Map && userUid != null
        ? sharedEngagement[userUid]
        : null;
    final sharedPartnerEngagement =
        sharedEngagement is Map && partnerUid != null
            ? sharedEngagement[partnerUid]
            : null;
    final userEngagement = sharedUserEngagement is Map
        ? sharedUserEngagement
        : userData['weeklyEngagement'];
    final partnerEngagement = sharedPartnerEngagement is Map
        ? sharedPartnerEngagement
        : partnerData['weeklyEngagement'];

    return List<PulseData>.generate(7, (index) {
      final date = monday.add(Duration(days: index));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      return PulseData(
        day: dayLabels[index],
        userCount: _engagementCountForDate(userEngagement, dateKey),
        partnerCount: _engagementCountForDate(partnerEngagement, dateKey),
      );
    });
  }

  int _engagementCountForDate(dynamic engagement, String dateKey) {
    if (engagement is! Map) return 0;
    final value = engagement[dateKey];
    return value is num ? value.toInt() : 0;
  }

  @override
  Future<void> close() {
    _userSub?.cancel();
    _partnerSub?.cancel();
    _coupleSub?.cancel();
    _batteryTimer?.cancel();
    return super.close();
  }
}
