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

    // ── Step 1: Check the local "profile complete" flag ──
    final localProfileComplete = isProfileCompleteLocally(uid);
    if (localProfileComplete) {
      dev.log(
          '[ProfileGate] Local flag says profile is complete — checking pair status.',
          name: 'ProfileGateService');
      return _decidePairStatus(uid);
    }

    // ── Step 2: Check Firestore (via cache service) ──
    Map<String, dynamic>? userData;
    try {
      userData = await _cache.getDocument(
        ref: _firestore.collection('users').doc(uid),
        cacheKey: _userCacheKey(uid),
        ttl: const Duration(minutes: 5),
      );
    } catch (e) {
      dev.log(
          '[ProfileGate] Firestore fetch failed: $e — falling back to local.',
          name: 'ProfileGateService');
    }

    if (userData != null) {
      final serverProfileComplete =
          (userData['profileComplete'] as bool? ?? false) ||
              (userData['nickname'] as String? ?? '').isNotEmpty;

      if (serverProfileComplete) {
        // Server says complete → set local flag so we never re-check.
        markProfileComplete(uid);

        // Also cache the pair status locally.
        final pairStatus = userData['pairStatus'] as String? ?? 'none';
        markPairStatus(uid, pairStatus);

        return _decidePairStatusFromValue(pairStatus);
      } else {
        // Server has the document but profile is genuinely incomplete.
        dev.log(
            '[ProfileGate] Server says profile is NOT complete (profileComplete=false, nickname empty).',
            name: 'ProfileGateService');
        return NavigationDecision.goToProfileSetup;
      }
    }

    // ── Step 3: Firestore returned null (doc missing or offline) ──
    // This happens for genuinely new users or when offline with empty cache.
    dev.log(
        '[ProfileGate] No Firestore data and no local flag — assuming profile setup required.',
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
