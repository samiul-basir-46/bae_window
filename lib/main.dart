import 'package:bea_window_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:bea_window_app/loading_screen.dart';
import 'package:bea_window_app/features/chat_overlay/presentation/overlay_screen.dart';
import 'package:bea_window_app/features/chat_overlay/services/chat_head_sync_service.dart';
import 'dart:io';
import 'package:bea_window_app/features/story/presentation/bloc/story_bloc.dart';
import 'package:bea_window_app/features/story/presentation/bloc/story_event.dart';
import 'package:bea_window_app/features/space_screen/bloc/space_screen_bloc.dart';
import 'package:bea_window_app/features/space_screen/bloc/space_screen_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:auto_animated/auto_animated.dart';
import 'package:bea_window_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'constants/custome_theme.dart';
import 'gen/colors.gen.dart';
import 'helpers/all_routes.dart';
import 'helpers/di.dart';
import 'helpers/helper_methods.dart';
import 'helpers/navigation_service.dart';
import 'helpers/notification_service.dart';
import 'networks/dio/dio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GetStorage.init();
  diSetup();
  PushNotificationService.registerBackgroundHandler();
  await PushNotificationService.initialize();
  // initiInternetChecker();
  // await LocationService.instance.initialize();
  DioSingleton.instance.create();
  if (Platform.isAndroid) {
    ChatHeadSyncService().startSync();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    rotation();
    setInitValue();
    return AnimateIfVisibleWrapper(
      showItemInterval: const Duration(milliseconds: 150),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, _) async {
          showMaterialDialog(context);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return const UtillScreenMobile();
          },
        ),
      ),
    );
  }
}

class UtillScreenMobile extends StatelessWidget {
  const UtillScreenMobile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, _) async {
            showMaterialDialog(context);
          },
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>(
                create: (_) => AuthBloc(),
              ),
              BlocProvider<OnboardingBloc>(
                create: (_) => OnboardingBloc(),
              ),
              BlocProvider<StoryBloc>(
                create: (_) => StoryBloc()..add(const LoadMemoriesEvent()),
              ),
              BlocProvider<SpaceScreenBloc>(
                create: (_) => SpaceScreenBloc()..add(const LoadSpaceScreenDataEvent()),
              ),
            ],
            child: MaterialApp(
                theme: ThemeData(
                    unselectedWidgetColor: Colors.white,
                    primarySwatch: CustomTheme.kToDark,
                    useMaterial3: false,
                    scaffoldBackgroundColor: AppColors.cFFFFFF,
                    appBarTheme: const AppBarTheme(
                        backgroundColor: AppColors.cFFFFFF, elevation: 0)),
                debugShowCheckedModeBanner: false,
                builder: (context, widget) {
                  return MediaQuery(
                      data: MediaQuery.of(context), child: widget!);
                },
                navigatorKey: NavigationService.navigatorKey,
                onGenerateRoute: RouteGenerator.generateRoute,
                home: const Loading()),
          ),
        );
      },
    );
  }
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: OverlayScreen(),
        );
      },
    ),
  );
}
