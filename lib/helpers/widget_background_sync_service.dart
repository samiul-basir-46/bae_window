import 'dart:developer' as dev;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:get_storage/get_storage.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';
import 'notification_service.dart';

const String widgetHourlySyncTask = 'bloom.widget.hourlySync';
const String _widgetHourlySyncUniqueName = 'bloom_widget_hourly_sync';

@pragma('vm:entry-point')
void widgetBackgroundSyncDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      await GetStorage.init();
      await PushNotificationService.syncWidgetFromFirestore();
      return true;
    } catch (e, stack) {
      dev.log(
        'Widget WorkManager sync failed',
        name: 'WidgetBackgroundSyncService',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  });
}

class WidgetBackgroundSyncService {
  const WidgetBackgroundSyncService._();

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    await Workmanager().initialize(
      widgetBackgroundSyncDispatcher,
    );

    await Workmanager().registerPeriodicTask(
      _widgetHourlySyncUniqueName,
      widgetHourlySyncTask,
      frequency: const Duration(hours: 1),
      initialDelay: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
