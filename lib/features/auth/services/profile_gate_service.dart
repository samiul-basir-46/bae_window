import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/helpers/di.dart';
import 'package:bea_window_app/helpers/firestore_cache_service.dart';

/// The result of a profile gate check — determines where the user should navigate.
enum NavigationDecision {
  /// Profile is incomplete — go to ProfileSetupScreen
  goToProfileSetup,

  /// Profile is complete but pairing is pending — go to PairingScreen
  goToPairing,

  /// Profile is complete and pairing is done — go to NavigationScreen (Home)
  goToHome,
}

/// Centralized, single source of truth for determining whether a user's
/// profile/pairing onboarding is complete.
///
/// Priority chain: Local flag → Firestore cache → Firestore server.
/// Once a local flag says "complete", the user is NEVER redirected back to
/// profile setup, regardless of what the server returns.
class ProfileGateService {
  ProfileGateService._();
  static final ProfileGateService instance = ProfileGateService._();

  final FirestoreCacheService _cache = FirestoreCacheService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Local Storage Keys ────────────────────────────────────────────────
  String _profileCompleteKey(String uid) => 'profile_complete_$uid';
  String _pairStatusKey(String uid) => 'pair_status_$uid';
  String _userCacheKey(String uid) => 'users/$uid';

  // ─── Flags ─────────────────────────────────────────────────────────────

  /// Mark profile as complete in local storage.
  /// Once set, this user will NEVER be sent back to ProfileSetupScreen.
  void markProfileComplete(String uid) {
    appData.write(_profileCompleteKey(uid), true);
    dev.log('[ProfileGate] Marked profile complete for $uid (local flag)',
        name: 'ProfileGateService');
  }

  /// Mark pair status in local storage.
  void markPairStatus(String uid, String status) {
    appData.write(_pairStatusKey(uid), status);
    dev.log('[ProfileGate] Marked pair status=$status for $uid (local flag)',
        name: 'ProfileGateService');
  }

  /// Check if the local flag says profile is complete.
  bool isProfileCompleteLocally(String uid) {
    return appData.read<bool>(_profileCompleteKey(uid)) ?? false;
  }

  /// Read the locally-stored pair status.
  String getPairStatusLocally(String uid) {
    return appData.read<String>(_pairStatusKey(uid)) ?? 'none';
  }

  // ─── Navigation Decision ──────────────────────────────────────────────

  /// The single, deterministic navigation decision method.
  ///
  /// 1. If local flag says profile is complete → trust it, never re-redirect.
  /// 2. Otherwise, check Firestore (cache first, then server).
  /// 3. If Firestore is unavailable AND no local flag → assume incomplete
  ///    (this only happens on truly first-time users).
  Future<NavigationDecision> getNavigationDecision(String uid) async {
    dev.log('[ProfileGate] Evaluating navigation for uid=$uid',
        name: 'ProfileGateService');

    // ── Step 1: Check Firestore (cache first, then server) ──
    Map<String, dynamic>? userData;
    try {
      userData = await _cache.getDocument(
        ref: _firestore.collection('users').doc(uid),
        cacheKey: _userCacheKey(uid),
        ttl: const Duration(minutes: 5),
      );
    } catch (e) {
      dev.log(
          '[ProfileGate] Firestore fetch failed: $e — trying local storage fallback.',
          name: 'ProfileGateService');
    }

    if (userData != null) {
      final nickname = userData['nickname'] as String? ?? '';
      final gender = userData['gender'] as String? ?? '';
      final profileComplete = userData['profileComplete'] as bool? ?? false;

      // Profile is complete only if nickname and gender are both set and profileComplete is true
      final isComplete = profileComplete && nickname.isNotEmpty && gender.isNotEmpty;

      if (isComplete) {
        dev.log('[ProfileGate] Firestore data verified complete — saving local flags.',
            name: 'ProfileGateService');
        markProfileComplete(uid);

        final pairStatus = userData['pairStatus'] as String? ?? 'none';
        markPairStatus(uid, pairStatus);

        return _decidePairStatusFromValue(pairStatus);
      } else {
        dev.log(
            '[ProfileGate] Firestore says profile is INCOMPLETE: nickname="$nickname", gender="$gender", profileComplete=$profileComplete',
            name: 'ProfileGateService');
        // Ensure local flag is cleared if it was set incorrectly
        appData.write(_profileCompleteKey(uid), false);
        return NavigationDecision.goToProfileSetup;
      }
    }

    // ── Step 2: Offline fallback to local storage ──
    final localProfileComplete = isProfileCompleteLocally(uid);
    if (localProfileComplete) {
      dev.log(
          '[ProfileGate] Firestore offline, but local flag says profile is complete.',
          name: 'ProfileGateService');
      return _decidePairStatus(uid);
    }

    dev.log(
        '[ProfileGate] Offline and no local flag — assuming profile setup required.',
        name: 'ProfileGateService');
    return NavigationDecision.goToProfileSetup;
  }

  /// Decide navigation based on pair status, fetching from Firestore if needed.
  Future<NavigationDecision> _decidePairStatus(String uid) async {
    // First check local
    String pairStatus = getPairStatusLocally(uid);

    // If local has a definitive status, use it.
    if (pairStatus == 'paired' || pairStatus == 'unpaired') {
      dev.log(
          '[ProfileGate] Local pair status=$pairStatus → goToHome',
          name: 'ProfileGateService');
      return NavigationDecision.goToHome;
    }

    // Otherwise, try Firestore
    try {
      final userData = await _cache.getDocument(
        ref: _firestore.collection('users').doc(uid),
        cacheKey: _userCacheKey(uid),
        ttl: const Duration(minutes: 5),
      );
      if (userData != null) {
        pairStatus = userData['pairStatus'] as String? ?? 'none';
        markPairStatus(uid, pairStatus);
      }
    } catch (e) {
      dev.log(
          '[ProfileGate] Firestore unavailable for pair status check: $e',
          name: 'ProfileGateService');
    }

    return _decidePairStatusFromValue(pairStatus);
  }

  /// Pure logic: given a pair status string, return the navigation decision.
  NavigationDecision _decidePairStatusFromValue(String pairStatus) {
    if (pairStatus == 'paired' || pairStatus == 'unpaired') {
      dev.log('[ProfileGate] Pair status=$pairStatus → goToHome',
          name: 'ProfileGateService');
      return NavigationDecision.goToHome;
    }
    dev.log('[ProfileGate] Pair status=$pairStatus → goToPairing',
        name: 'ProfileGateService');
    return NavigationDecision.goToPairing;
  }
}
