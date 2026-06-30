import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:bea_window_app/features/auth/presentation/screens/login_screen.dart';
import 'package:bea_window_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:bea_window_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bea_window_app/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:bea_window_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:bea_window_app/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:bea_window_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:bea_window_app/navigation_screen.dart';

// Space Feature Screens
import 'package:bea_window_app/features/space/presentation/screens/vault_screen.dart';
import 'package:bea_window_app/features/space/presentation/screens/bucket_list_screen.dart';
import 'package:bea_window_app/features/space/presentation/screens/tasks_screen.dart';
import 'package:bea_window_app/features/space/presentation/screens/love_note_screen.dart';

// Nest Feature Screens
import 'package:bea_window_app/features/nest/presentation/screens/my_profile_screen.dart';
import 'package:bea_window_app/features/nest/presentation/screens/export_memories_screen.dart';
import 'package:bea_window_app/features/nest/presentation/screens/account_pairing_screen.dart';
import 'package:bea_window_app/features/change_password/presentation/screens/change_password_screen.dart';
import 'package:bea_window_app/features/change_vault_passcode/presentation/screens/change_vault_passcode_screen.dart';
import 'package:bea_window_app/features/notification_settings/presentation/screens/notification_settings_screen.dart';

final class Routes {
  static final Routes _routes = Routes._internal();
  Routes._internal();
  static Routes get instance => _routes;

  // Auth Routes
  static const String loginScreen = '/logIn';
  static const String signUpScreen = '/signUp';
  static const String forgotPasswordScreen = '/forgotPassword';
  static const String otpVerificationScreen = '/otpVerification';
  static const String resetPasswordScreen = '/resetPassword';
  static const String onboardingScreen = '/onboarding';
  static const String navigationScreen = '/navigation';
  static const String emailVerificationScreen = '/emailVerification';

  // Space Routes
  static const String vaultScreen = '/vault';
  static const String bucketListScreen = '/bucketList';
  static const String tasksScreen = '/tasks';
  static const String loveNoteScreen = '/loveNote';

  // Nest Routes
  static const String myProfileScreen = '/myProfile';
  static const String exportMemoriesScreen = '/exportMemories';
  static const String accountPairingScreen = '/accountPairing';
  static const String changePasswordScreen = '/changePassword';
  static const String changeVaultPasscodeScreen = '/changeVaultPasscode';
  static const String notificationSettingsScreen = '/notificationSettings';
}

final class RouteGenerator {
  static final RouteGenerator _routeGenerator = RouteGenerator._internal();
  RouteGenerator._internal();
  static RouteGenerator get instance => _routeGenerator;

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes
      case Routes.loginScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(builder: (context) => const LoginScreen())
            : _FadedTransitionRoute(
                widget: const LoginScreen(), settings: settings);

      case Routes.onboardingScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(builder: (context) => const OnboardingScreen())
            : _FadedTransitionRoute(
                widget: const OnboardingScreen(), settings: settings);

      case Routes.signUpScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(builder: (context) => const SignUpScreen())
            : _FadedTransitionRoute(
                widget: const SignUpScreen(), settings: settings);

      case Routes.forgotPasswordScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(builder: (context) => const ForgotPasswordScreen())
            : _FadedTransitionRoute(
                widget: const ForgotPasswordScreen(), settings: settings);

      case Routes.otpVerificationScreen:
        final args = settings.arguments;
        final String email;
        final bool isFromSignUp;
        final String? name;
        final String? password;
        if (args is Map<String, dynamic>) {
          email = args['email'] as String? ?? '';
          isFromSignUp = args['isFromSignUp'] as bool? ?? false;
          name = args['name'] as String?;
          password = args['password'] as String?;
        } else {
          email = args as String? ?? '';
          isFromSignUp = false;
          name = null;
          password = null;
        }
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(
                builder: (context) => OtpVerificationScreen(
                      email: email,
                      isFromSignUp: isFromSignUp,
                      name: name,
                      password: password,
                    ))
            : _FadedTransitionRoute(
                widget: OtpVerificationScreen(
                  email: email,
                  isFromSignUp: isFromSignUp,
                  name: name,
                  password: password,
                ),
                settings: settings);

      case Routes.emailVerificationScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(builder: (context) => const EmailVerificationScreen())
            : _FadedTransitionRoute(
                widget: const EmailVerificationScreen(), settings: settings);

      case Routes.resetPasswordScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(builder: (context) => const ResetPasswordScreen())
            : _FadedTransitionRoute(
                widget: const ResetPasswordScreen(), settings: settings);

      case Routes.navigationScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(builder: (context) => const NavigationScreen())
            : _FadedTransitionRoute(
                widget: const NavigationScreen(), settings: settings);

      // Space Routes
      case Routes.vaultScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(builder: (context) => const VaultScreen())
            : _FadedTransitionRoute(
                widget: const VaultScreen(), settings: settings);

      case Routes.bucketListScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(builder: (context) => const BucketListScreen())
            : _FadedTransitionRoute(
                widget: const BucketListScreen(), settings: settings);

      case Routes.tasksScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(builder: (context) => const TasksScreen())
            : _FadedTransitionRoute(
                widget: const TasksScreen(), settings: settings);

      case Routes.loveNoteScreen:
        final onSendCallback = settings.arguments as Function(String)?;
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(
                builder: (context) => LoveNoteScreen(onSend: onSendCallback))
            : _FadedTransitionRoute(
                widget: LoveNoteScreen(onSend: onSendCallback),
                settings: settings);

      // Nest Routes
      case Routes.myProfileScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(builder: (context) => const MyProfileScreen())
            : _FadedTransitionRoute(
                widget: const MyProfileScreen(), settings: settings);

      case Routes.exportMemoriesScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(
                builder: (context) => const ExportMemoriesScreen())
            : _FadedTransitionRoute(
                widget: const ExportMemoriesScreen(), settings: settings);

      case Routes.accountPairingScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(
                builder: (context) => const AccountPairingScreen())
            : _FadedTransitionRoute(
                widget: const AccountPairingScreen(), settings: settings);

      case Routes.changePasswordScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(
                builder: (context) => const ChangePasswordScreen())
            : _FadedTransitionRoute(
                widget: const ChangePasswordScreen(), settings: settings);

      case Routes.changeVaultPasscodeScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(
                builder: (context) => const ChangeVaultPasscodeScreen())
            : _FadedTransitionRoute(
                widget: const ChangeVaultPasscodeScreen(), settings: settings);

      case Routes.notificationSettingsScreen:
        return defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoPageRoute(
                builder: (context) => const NotificationSettingsScreen())
            : _FadedTransitionRoute(
                widget: const NotificationSettingsScreen(), settings: settings);

      default:
        return null;
    }
  }
}

class _FadedTransitionRoute extends PageRouteBuilder {
  final Widget widget;
  @override
  final RouteSettings settings;

  _FadedTransitionRoute({required this.widget, required this.settings})
      : super(
          settings: settings,
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return widget;
          },
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.02),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
        );
}

class ScreenTitle extends StatelessWidget {
  final Widget widget;

  const ScreenTitle({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: .5, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.bounceIn,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: widget,
    );
  }
}
