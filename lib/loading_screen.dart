import 'dart:async';
import 'dart:developer';
import 'package:bea_window_app/features/auth/presentation/screens/login_screen.dart';
import 'package:bea_window_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:bea_window_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:bea_window_app/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:bea_window_app/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:bea_window_app/features/auth/presentation/screens/pairing_screen.dart';
import 'package:bea_window_app/navigation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import 'helpers/di.dart';
import 'helpers/firestore_cache_service.dart';
import 'helpers/helper_methods.dart';
import 'helpers/post_login.dart';
import 'networks/dio/dio.dart';

final class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  bool _isLoading = true;
  Widget _initialScreen = const LoginScreen();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    loadInitialData();
    final cachedFcmToken = appData.read<String>(kKeyFCMToken);
    if (cachedFcmToken != null && cachedFcmToken.isNotEmpty) {
      log("Cached FCM Token =======> $cachedFcmToken");
    }
    _timer = Timer(const Duration(seconds: 35), () {
      if (_isLoading) {
        _handleLogout();
      }
    });
  }

  loadInitialData() async {
    await setInitValue();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.reload().timeout(const Duration(seconds: 5));
      } catch (_) {}

      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser != null && !refreshedUser.emailVerified) {
        _initialScreen = const EmailVerificationScreen();
      } else if (refreshedUser != null) {
        final data = await FirestoreCacheService.instance
            .getDocument(
              ref: FirebaseFirestore.instance
                  .collection('users')
                  .doc(refreshedUser.uid),
              cacheKey: 'users/${refreshedUser.uid}',
              ttl: const Duration(minutes: 5),
            )
            .timeout(const Duration(seconds: 4), onTimeout: () => null);

        if (data != null) {
          final isProfileComplete =
              (data['profileComplete'] as bool? ?? false) ||
                  (data['nickname'] as String? ?? '').isNotEmpty;
          if (!isProfileComplete) {
            _initialScreen = const ProfileSetupScreen();
          } else {
            final pairStatus = data['pairStatus'] as String? ?? 'none';
            if (pairStatus == 'paired' || pairStatus == 'unpaired') {
              _initialScreen = const NavigationScreen();
            } else {
              _initialScreen = const PairingScreen();
            }
          }
        } else {
          if (appData.read(kKeyIsLoggedIn) == true) {
            _initialScreen = const NavigationScreen();
          } else {
            _initialScreen = const ProfileSetupScreen();
          }
        }
      }
    } else {
      _initialScreen = appData.read(kKeyfirstTime)
          ? const OnboardingScreen()
          : const LoginScreen();
    }

    if (appData.read(kKeyIsLoggedIn)) {
      final token = appData.read(kKeyAccessToken)?.toString() ?? '';
      if (token.isNotEmpty) {
        DioSingleton.instance.update(token);
      }
      await performPostLoginActions();
    }

    if (mounted) {
      setState(() {
        _timer?.cancel();
        _isLoading = false;
      });
    }
  }

  void _handleLogout() {
    appData.write(kKeyIsLoggedIn, false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    } else {
      return _initialScreen;
    }
  }
}
